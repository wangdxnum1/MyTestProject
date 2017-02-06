/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageCache.h"
#import "SDWebImageDecoder.h"
#import "UIImage+MultiFormat.h"
#import <CommonCrypto/CommonDigest.h>

// See https://github.com/rs/SDWebImage/pull/1141 for discussion
// 继承系统的NSCache，主要注册了UIApplicationDidReceiveMemoryWarningNotification这个通知，
// 自动清理聂村
@interface AutoPurgeCache : NSCache
@end

@implementation AutoPurgeCache

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

}

@end

static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week
// PNG signature bytes and data (below)
static unsigned char kPNGSignatureBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
static NSData *kPNGSignatureData = nil;

BOOL ImageDataHasPNGPreffix(NSData *data);

BOOL ImageDataHasPNGPreffix(NSData *data) {
    NSUInteger pngSignatureLength = [kPNGSignatureData length];
    if ([data length] >= pngSignatureLength) {
        if ([[data subdataWithRange:NSMakeRange(0, pngSignatureLength)] isEqualToData:kPNGSignatureData]) {
            return YES;
        }
    }

    return NO;
}

FOUNDATION_STATIC_INLINE NSUInteger SDCacheCostForImage(UIImage *image) {
    return image.size.height * image.size.width * image.scale * image.scale;
}

@interface SDImageCache ()

// 内存缓存
@property (strong, nonatomic) NSCache *memCache;

// disk缓存路径
@property (strong, nonatomic) NSString *diskCachePath;

// 自定义路径，可能disk缓存的路径吧
@property (strong, nonatomic) NSMutableArray *customPaths;

// 进行io操作的队列
@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t ioQueue;

@end


@implementation SDImageCache {
    NSFileManager *_fileManager;
}

+ (SDImageCache *)sharedImageCache {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init {
    return [self initWithNamespace:@"default"];
}

- (id)initWithNamespace:(NSString *)ns {
    NSString *path = [self makeDiskCachePath:ns];
    return [self initWithNamespace:ns diskCacheDirectory:path];
}

// 初始化工作，disk路径，缓存事件，一些默认设置，创建资源，io队列，fileManager

- (id)initWithNamespace:(NSString *)ns diskCacheDirectory:(NSString *)directory {
    if ((self = [super init])) {
        // disk 缓存的路径，根据namespace，来组装
        NSString *fullNamespace = [@"com.hackemist.SDWebImageCache." stringByAppendingString:ns];

        // initialise PNG signature data
        kPNGSignatureData = [NSData dataWithBytes:kPNGSignatureBytes length:8];

        // Create IO serial queue
        // io 的线性队列
        _ioQueue = dispatch_queue_create("com.hackemist.SDWebImageCache", DISPATCH_QUEUE_SERIAL);

        // Init default values
        // 默认的缓存时间。1 week
        _maxCacheAge = kDefaultCacheMaxCacheAge;

        // Init the memory cache
        // 创建内存缓存
        _memCache = [[AutoPurgeCache alloc] init];
        _memCache.name = fullNamespace;

        // Init the disk cache
        if (directory != nil) {
            // disk缓存路径，跟namespace 相关
            //.../Caches/default/com.hackemist.SDWebImageCache.default/
            _diskCachePath = [directory stringByAppendingPathComponent:fullNamespace];
        } else {
            //.../Caches/default/
            NSString *path = [self makeDiskCachePath:ns];
            _diskCachePath = path;
        }

        // Set decompression to YES
        _shouldDecompressImages = YES;

        // memory cache enabled
        _shouldCacheImagesInMemory = YES;

        // Disable iCloud
        _shouldDisableiCloud = YES;

        dispatch_sync(_ioQueue, ^{
            // 获取文件manager
            _fileManager = [NSFileManager new];
        });

#if TARGET_OS_IOS
        // Subscribe to app events
        // 订阅app 的事件，例如收到内存警告，进入后台，将终止
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundCleanDisk)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
#endif
    }

    return self;
}

// 还需研究这个函数的用处
- (void)addReadOnlyCachePath:(NSString *)path {
    if (!self.customPaths) {
        self.customPaths = [NSMutableArray new];
    }

    if (![self.customPaths containsObject:path]) {
        [self.customPaths addObject:path];
    }
}

#pragma mark ImageCache

- (void)storeImage:(UIImage *)image recalculateFromImage:(BOOL)recalculate imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk {
    if (!image || !key) {
        return;
    }
    
    // if memory cache is enabled
    // 用系统的NSCache 缓存图片
    if (self.shouldCacheImagesInMemory) {
        NSUInteger cost = SDCacheCostForImage(image);
        [self.memCache setObject:image forKey:key cost:cost];
    }

    // 缓存到disk
    if (toDisk) {
        dispatch_async(self.ioQueue, ^{
            // 线性队列，异步操作
            NSData *data = imageData;

            if (image && (recalculate || !data)) {
#if TARGET_OS_IPHONE
                // We need to determine if the image is a PNG or a JPEG
                // PNGs are easier to detect because they have a unique signature (http://www.w3.org/TR/PNG-Structure.html)
                // The first eight bytes of a PNG file always contain the following (decimal) values:
                // 137 80 78 71 13 10 26 10

                // If the imageData is nil (i.e. if trying to save a UIImage directly or the image was transformed on download)
                // and the image has an alpha channel, we will consider it PNG to avoid losing the transparency
                int alphaInfo = CGImageGetAlphaInfo(image.CGImage);
                BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                                  alphaInfo == kCGImageAlphaNoneSkipFirst ||
                                  alphaInfo == kCGImageAlphaNoneSkipLast);
                BOOL imageIsPng = hasAlpha;

                // But if we have an image data, we will look at the preffix
                if ([imageData length] >= [kPNGSignatureData length]) {
                    imageIsPng = ImageDataHasPNGPreffix(imageData);
                }

                if (imageIsPng) {
                    // png
                    data = UIImagePNGRepresentation(image);
                }
                else {
                    // jpeg
                    data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
                }
#else
                data = [NSBitmapImageRep representationOfImageRepsInArray:image.representations usingType: NSJPEGFileType properties:nil];
#endif
            }
            
            // 换粗图片到disk
            NSLog(@"storeImageDataToDisk");
            [self storeImageDataToDisk:data forKey:key];
        });
    }
}

// 缓存图片到内存和disk
- (void)storeImage:(UIImage *)image forKey:(NSString *)key {
    [self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:YES];
}

// 缓存图片到内存和disk，但是disk 是可选的
- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk {
    [self storeImage:image recalculateFromImage:YES imageData:nil forKey:key toDisk:toDisk];
}

// 缓存图片到disk
- (void)storeImageDataToDisk:(NSData *)imageData forKey:(NSString *)key {
    
    if (!imageData) {
        return;
    }
    
    // 判断缓存文件路径是否存在，不存在，则新建path
    if (![_fileManager fileExistsAtPath:_diskCachePath]) {
        [_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    // get cache Path for image key
    // 获取默认的disk 缓存路径
    NSString *cachePathForKey = [self defaultCachePathForKey:key];
    // transform to NSUrl
    NSURL *fileURL = [NSURL fileURLWithPath:cachePathForKey];
    
    // 保存文件
    BOOL exist = [_fileManager fileExistsAtPath:cachePathForKey];
    NSLog(@"fileExistsAtPath exist = %d",exist);
    
    
    BOOL bRet = [_fileManager createFileAtPath:cachePathForKey contents:imageData attributes:nil];
    NSLog(@"createFileAtPath bRet = %d",bRet);
    // disable iCloud backup
    if (self.shouldDisableiCloud) {
        // 不保存到iCloud
        [fileURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
}

// 根据key,判断disk缓存是否存在
- (BOOL)diskImageExistsWithKey:(NSString *)key {
    BOOL exists = NO;
    
    // this is an exception to access the filemanager on another queue than ioQueue, but we are using the shared instance
    // from apple docs on NSFileManager: The methods of the shared NSFileManager object can be called from multiple threads safely.
    // 这个方法并没有在ioQueue 里访问 fileManager，但是根据苹果文档这个是线程安全的
    exists = [[NSFileManager defaultManager] fileExistsAtPath:[self defaultCachePathForKey:key]];

    // fallback because of https://github.com/rs/SDWebImage/pull/976 that added the extension to the disk file name
    // checking the key with and without the extension
    // 没有后缀名的也检查下
    if (!exists) {
        exists = [[NSFileManager defaultManager] fileExistsAtPath:[[self defaultCachePathForKey:key] stringByDeletingPathExtension]];
    }
    
    return exists;
}

// 异步查找，立马返回
- (void)diskImageExistsWithKey:(NSString *)key completion:(SDWebImageCheckCacheCompletionBlock)completionBlock {
    dispatch_async(_ioQueue, ^{
        // 查找文件是否存在
        BOOL exists = [_fileManager fileExistsAtPath:[self defaultCachePathForKey:key]];

        // fallback because of https://github.com/rs/SDWebImage/pull/976 that added the extension to the disk file name
        // checking the key with and without the extension
        if (!exists) {
            exists = [_fileManager fileExistsAtPath:[[self defaultCachePathForKey:key] stringByDeletingPathExtension]];
        }

        if (completionBlock) {
            // 回调到主线程
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(exists);
            });
        }
    });
}

// 内存缓存，nscache中取出缓存的对象
- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key {
    return [self.memCache objectForKey:key];
}

// 获取disk里的image
- (UIImage *)imageFromDiskCacheForKey:(NSString *)key {

    // First check the in-memory cache...
    // 检查内存缓存里是有有缓存，有的话，直接返回
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image) {
        return image;
    }

    // Second check the disk cache...
    UIImage *diskImage = [self diskImageForKey:key];
    if (diskImage && self.shouldCacheImagesInMemory) {
        // 到这里说明内存没有缓存，shouldCacheImagesInMemory为也是，则缓存到内存
        NSUInteger cost = SDCacheCostForImage(diskImage);
        [self.memCache setObject:diskImage forKey:key cost:cost];
    }

    return diskImage;
}

- (NSData *)diskImageDataBySearchingAllPathsForKey:(NSString *)key {
    // 返回二进制数据
    NSString *defaultPath = [self defaultCachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:defaultPath];
    if (data) {
        return data;
    }

    // fallback because of https://github.com/rs/SDWebImage/pull/976 that added the extension to the disk file name
    // checking the key with and without the extension
    // 没有后缀名的也需要检查下
    data = [NSData dataWithContentsOfFile:[defaultPath stringByDeletingPathExtension]];
    if (data) {
        return data;
    }

    NSArray *customPaths = [self.customPaths copy];
    for (NSString *path in customPaths) {
        // 自定义路径的也查找下
        NSString *filePath = [self cachePathForKey:key inPath:path];
        NSData *imageData = [NSData dataWithContentsOfFile:filePath];
        if (imageData) {
            return imageData;
        }

        // fallback because of https://github.com/rs/SDWebImage/pull/976 that added the extension to the disk file name
        // checking the key with and without the extension
        imageData = [NSData dataWithContentsOfFile:[filePath stringByDeletingPathExtension]];
        if (imageData) {
            return imageData;
        }
    }

    return nil;
}

// 返回disk 缓存的image
- (UIImage *)diskImageForKey:(NSString *)key {
    NSData *data = [self diskImageDataBySearchingAllPathsForKey:key];
    if (data) {
        // 生成image 对象，用了自己的方法，并且做了缩放
        UIImage *image = [UIImage sd_imageWithData:data];
        image = [self scaledImageForKey:key image:image];
        if (self.shouldDecompressImages) {
            // 解压，具体还不理解
            image = [UIImage decodedImageWithImage:image];
        }
        return image;
    }
    else {
        return nil;
    }
}

// 需要知道执行这个的作用
- (UIImage *)scaledImageForKey:(NSString *)key image:(UIImage *)image {
    return SDScaledImageForKey(key, image);
}

- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(SDWebImageQueryCompletedBlock)doneBlock {
    if (!doneBlock) {
        return nil;
    }

    if (!key) {
        doneBlock(nil, SDImageCacheTypeNone);
        return nil;
    }

    // First check the in-memory cache...
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image) {
        doneBlock(image, SDImageCacheTypeMemory);
        return nil;
    }

    NSOperation *operation = [NSOperation new];
    dispatch_async(self.ioQueue, ^{
        if (operation.isCancelled) {
            return;
        }

        @autoreleasepool {
            UIImage *diskImage = [self diskImageForKey:key];
            if (diskImage && self.shouldCacheImagesInMemory) {
                NSUInteger cost = SDCacheCostForImage(diskImage);
                [self.memCache setObject:diskImage forKey:key cost:cost];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                doneBlock(diskImage, SDImageCacheTypeDisk);
            });
        }
    });

    return operation;
}

// 根据key 移除缓存image，包括内存和disk
- (void)removeImageForKey:(NSString *)key {
    [self removeImageForKey:key withCompletion:nil];
}

// 有回调的移除
- (void)removeImageForKey:(NSString *)key withCompletion:(SDWebImageNoParamsBlock)completion {
    [self removeImageForKey:key fromDisk:YES withCompletion:completion];
}

// 可选的移除disk缓存
- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk {
    [self removeImageForKey:key fromDisk:fromDisk withCompletion:nil];
}

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk withCompletion:(SDWebImageNoParamsBlock)completion {
    
    if (key == nil) {
        return;
    }

    if (self.shouldCacheImagesInMemory) {
        // 先移除内存缓存
        [self.memCache removeObjectForKey:key];
    }

    if (fromDisk) {
        // 异步移除
        dispatch_async(self.ioQueue, ^{
            [_fileManager removeItemAtPath:[self defaultCachePathForKey:key] error:nil];
            
            // 删除了文件通知
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion();
                });
            }
        });
    } else if (completion){
        completion();
    }
    
}

// 内存缓存最大缓存内存设置
- (void)setMaxMemoryCost:(NSUInteger)maxMemoryCost {
    self.memCache.totalCostLimit = maxMemoryCost;
}

// 获取最大内存你的缓存
- (NSUInteger)maxMemoryCost {
    return self.memCache.totalCostLimit;
}

// 返回最大内存个数
- (NSUInteger)maxMemoryCountLimit {
    return self.memCache.countLimit;
}

// 设置最大缓存个数
- (void)setMaxMemoryCountLimit:(NSUInteger)maxCountLimit {
    self.memCache.countLimit = maxCountLimit;
}

// 清空内存缓存
- (void)clearMemory {
    [self.memCache removeAllObjects];
}

// 清除disk缓存，所有的
- (void)clearDisk {
    [self clearDiskOnCompletion:nil];
}

// 有回调的清除disk缓存
- (void)clearDiskOnCompletion:(SDWebImageNoParamsBlock)completion
{
    dispatch_async(self.ioQueue, ^{
        // 删除这个文件夹，即删除了所有文件
        [_fileManager removeItemAtPath:self.diskCachePath error:nil];
        // 再新建这个文件
        [_fileManager createDirectoryAtPath:self.diskCachePath
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:NULL];
        
        // 回调通知
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}

// ??clearDisk 的区别，cleanDisk 清除过期的数据
- (void)cleanDisk {
    [self cleanDiskWithCompletionBlock:nil];
}

- (void)cleanDiskWithCompletionBlock:(SDWebImageNoParamsBlock)completionBlock {
    dispatch_async(self.ioQueue, ^{
        NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
        NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];

        // This enumerator prefetches useful properties for our cache files.
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];

        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
        NSMutableDictionary *cacheFiles = [NSMutableDictionary dictionary];
        NSUInteger currentCacheSize = 0;

        // Enumerate all of the files in the cache directory.  This loop has two purposes:
        //
        //  1. Removing files that are older than the expiration date.
        //  2. Storing file attributes for the size-based cleanup pass.
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in fileEnumerator) {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:NULL];

            // Skip directories.
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }

            // Remove files that are older than the expiration date;
            // 删除比过期时间大的文件，比如3天过期，4天以前的就要删掉,把File url 保存到要删除数组中
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [urlsToDelete addObject:fileURL];
                continue;
            }

            // Store a reference to this file and account for its total size.
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize += [totalAllocatedSize unsignedIntegerValue];
            [cacheFiles setObject:resourceValues forKey:fileURL];
        }
        
        for (NSURL *fileURL in urlsToDelete) {
            [_fileManager removeItemAtURL:fileURL error:nil];
        }

        // If our remaining disk cache exceeds a configured maximum size, perform a second
        // size-based cleanup pass.  We delete the oldest files first.
        // 如果disk换粗大于最大缓存，删除文件，知道小于最大缓存的1/2
        if (self.maxCacheSize > 0 && currentCacheSize > self.maxCacheSize) {
            // Target half of our maximum cache size for this cleanup pass.
            const NSUInteger desiredCacheSize = self.maxCacheSize / 2;

            // Sort the remaining cache files by their last modification time (oldest first).
            NSArray *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                            usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
                                                            }];

            // Delete files until we fall below our desired cache size.
            for (NSURL *fileURL in sortedFiles) {
                if ([_fileManager removeItemAtURL:fileURL error:nil]) {
                    NSDictionary *resourceValues = cacheFiles[fileURL];
                    NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                    currentCacheSize -= [totalAllocatedSize unsignedIntegerValue];

                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                }
            }
        }
        if (completionBlock) {
            // 回调操作
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
    });
}

// 进入程序进入后台会执行这个函数，切刀后台来执行一些清理工作
- (void)backgroundCleanDisk {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

    // Start the long-running task and return immediately.
    [self cleanDiskWithCompletionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

// 同步计算disk缓存文件大小。default
- (NSUInteger)getSize {
    __block NSUInteger size = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:self.diskCachePath];
        for (NSString *fileName in fileEnumerator) {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            size += [attrs fileSize];
        }
    });
    return size;
}

// disk 缓存文件的个数
- (NSUInteger)getDiskCount {
    __block NSUInteger count = 0;
    dispatch_sync(self.ioQueue, ^{
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtPath:self.diskCachePath];
        count = [[fileEnumerator allObjects] count];
    });
    return count;
}

// 异步计算缓存文件大小和个数
- (void)calculateSizeWithCompletionBlock:(SDWebImageCalculateSizeBlock)completionBlock {
    NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];

    dispatch_async(self.ioQueue, ^{
        NSUInteger fileCount = 0;
        NSUInteger totalSize = 0;

        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:@[NSFileSize]
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];

        for (NSURL *fileURL in fileEnumerator) {
            NSNumber *fileSize;
            [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
            totalSize += [fileSize unsignedIntegerValue];
            fileCount += 1;
        }

        if (completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(fileCount, totalSize);
            });
        }
    });
}

// 得到图片的路径
- (NSString *)cachePathForKey:(NSString *)key inPath:(NSString *)path {
    // 得到图片的名字
    NSString *filename = [self cachedFileNameForKey:key];
    return [path stringByAppendingPathComponent:filename];
}

- (NSString *)defaultCachePathForKey:(NSString *)key {
    // 默认的 namespace default 路径 + 图片的名字
    return [self cachePathForKey:key inPath:self.diskCachePath];
}

#pragma mark SDImageCache (private)

// 具体操作，得到文件的名字，把key -> MD5, 16个字节，16 * 2 = 32 个字符，16进制，即0-f之间的字
// 符命名
- (NSString *)cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    // 16进制数据命名图片的名字
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [[key pathExtension] isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", [key pathExtension]]];
    
    return filename;
}

// Init the disk cache
-(NSString *)makeDiskCachePath:(NSString*)fullNamespace{
    
    // 沙盒cache目录 + nameSpace。例如 default
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    // /Users/hikim/Library/Developer/CoreSimulator/Devices/6AD407F6-876D-4586-9C58-B41114426A3F/data/Containers/Data/Application/844E0CBB-6D8D-4B70-829D-366F7E9883FD/Library/Caches/default
    return [paths[0] stringByAppendingPathComponent:fullNamespace];
}


- (void)dealloc {
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    SDDispatchQueueRelease(_ioQueue);
}


@end
