/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageManager.h"
#import <objc/message.h>

// 遵守了SDWebImageOperation协议的类，具有cancel的方法
@interface SDWebImageCombinedOperation : NSObject <SDWebImageOperation>

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@property (copy, nonatomic) SDWebImageNoParamsBlock cancelBlock;
@property (strong, nonatomic) NSOperation *cacheOperation;

@end

@interface SDWebImageManager ()

// 缓存器
@property (strong, nonatomic, readwrite) SDImageCache *imageCache;

// 下载器
@property (strong, nonatomic, readwrite) SDWebImageDownloader *imageDownloader;

// 下载失败的urls，是缓存在内存的，没有缓存在disk，所以app重启后，一开始是空的
@property (strong, nonatomic) NSMutableSet *failedURLs;

// 正在运行的operation
@property (strong, nonatomic) NSMutableArray *runningOperations;

@end

@implementation SDWebImageManager

// 获取全局的单例对象
+ (id)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

// 初始化。构建全局的cache 和 downloader
- (instancetype)init {
    SDImageCache *cache = [SDImageCache sharedImageCache];
    SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
    return [self initWithCache:cache downloader:downloader];
}

// 初始化
- (instancetype)initWithCache:(SDImageCache *)cache downloader:(SDWebImageDownloader *)downloader {
    if ((self = [super init])) {
        _imageCache = cache;
        _imageDownloader = downloader;
        _failedURLs = [NSMutableSet new];
        _runningOperations = [NSMutableArray new];
    }
    return self;
}

// 下载的操作

- (id <SDWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                         options:(SDWebImageOptions)options
                                        progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                       completed:(SDWebImageCompletionWithFinishedBlock)completedBlock {
    // Invoking this method without a completedBlock is pointless
    // completedBlock 一定要的
    NSAssert(completedBlock != nil, @"If you mean to prefetch the image, use -[SDWebImagePrefetcher prefetchURLs] instead");

    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    // 检查url的类型，如果是nsstring，容错
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }

    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    // 如果是NSnull，则转换为nil
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }

    __block SDWebImageCombinedOperation *operation = [SDWebImageCombinedOperation new];
    __weak SDWebImageCombinedOperation *weakOperation = operation;

    BOOL isFailedUrl = NO;
    @synchronized (self.failedURLs) {
        // 检查是不是失败的url
        isFailedUrl = [self.failedURLs containsObject:url];
    }

    if (url.absoluteString.length == 0 || (!(options & SDWebImageRetryFailed) && isFailedUrl)) {
        dispatch_main_sync_safe(^{
            // 无效的url，失败的url，并且不是失败重试的时候，就直接结束，报error，调用completedBlock
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil];
            completedBlock(nil, error, SDImageCacheTypeNone, YES, url);
        });
        return operation;
    }

    // 线程安全添加operation
    @synchronized (self.runningOperations) {
        [self.runningOperations addObject:operation];
    }
    // 根据url 得到 key
    NSString *key = [self cacheKeyForURL:url];

    operation.cacheOperation = [self.imageCache queryDiskCacheForKey:key done:^(UIImage *image, SDImageCacheType cacheType) {
        // 假如查询缓存时间很长，用户取消了操作，检测查询缓存operation取消了，就不执行下面的代码了
        if (operation.isCancelled) {
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }

            return;
        }

        // 1.图片不存在或者下载选项指定，即使缓存存在也要刷新
        // 2.没有代理，或者代理存在允许下载
        if ((!image || options & SDWebImageRefreshCached) && (![self.delegate respondsToSelector:@selector(imageManager:shouldDownloadImageForURL:)] || [self.delegate imageManager:self shouldDownloadImageForURL:url])) {
            
            // 缓存存在，但是需要重新下载
            if (image && options & SDWebImageRefreshCached) {
                dispatch_main_sync_safe(^{
                    // If image was found in the cache but SDWebImageRefreshCached is provided, notify about the cached image
                    // AND try to re-download it in order to let a chance to NSURLCache to refresh it from server.
                    // 有缓存，但是需要SDWebImageRefreshCached，先会掉一下completedBlock，所以以前旧得图片还是会显示出来
                    completedBlock(image, nil, cacheType, YES, url);
                });
            }

            // download if no image or requested to refresh anyway, and download allowed by delegate
            // 不存在缓存，或者需要刷新，而且代理允许下载
            
            // 转换下载选项
            SDWebImageDownloaderOptions downloaderOptions = 0;
            if (options & SDWebImageLowPriority) downloaderOptions |= SDWebImageDownloaderLowPriority;
            if (options & SDWebImageProgressiveDownload) downloaderOptions |= SDWebImageDownloaderProgressiveDownload;
            if (options & SDWebImageRefreshCached) downloaderOptions |= SDWebImageDownloaderUseNSURLCache;
            if (options & SDWebImageContinueInBackground) downloaderOptions |= SDWebImageDownloaderContinueInBackground;
            if (options & SDWebImageHandleCookies) downloaderOptions |= SDWebImageDownloaderHandleCookies;
            if (options & SDWebImageAllowInvalidSSLCertificates) downloaderOptions |= SDWebImageDownloaderAllowInvalidSSLCertificates;
            if (options & SDWebImageHighPriority) downloaderOptions |= SDWebImageDownloaderHighPriority;
            if (image && options & SDWebImageRefreshCached) {
                // 如果有缓存，而且需要重新下载，把SDWebImageDownloaderProgressiveDownload这个选项关掉
                // force progressive off if image already cached but forced refreshing
                downloaderOptions &= ~SDWebImageDownloaderProgressiveDownload;
                // ignore image read from NSURLCache if image if cached but force refreshing
                // 不从NSURLCache读取
                downloaderOptions |= SDWebImageDownloaderIgnoreCachedResponse;
            }
            
            // 交给下载器去下载图片，返回管理下载图片的operation，支持cancel操作
            id <SDWebImageOperation> subOperation = [self.imageDownloader downloadImageWithURL:url options:downloaderOptions progress:progressBlock completed:^(UIImage *downloadedImage, NSData *data, NSError *error, BOOL finished) {
                __strong __typeof(weakOperation) strongOperation = weakOperation;
                if (!strongOperation || strongOperation.isCancelled) {
                    // Do nothing if the operation was cancelled
                    // See #699 for more details
                    // if we would call the completedBlock, there could be a race condition between this block and another completedBlock for the same object, so if this one is called second, we will overwrite the new data
                }
                else if (error) {
                    // 现在有错误，回调block
                    dispatch_main_sync_safe(^{
                        if (strongOperation && !strongOperation.isCancelled) {
                            completedBlock(nil, error, SDImageCacheTypeNone, finished, url);
                        }
                    });

                    // 失败的无效的url定义，
                    if (   error.code != NSURLErrorNotConnectedToInternet
                        && error.code != NSURLErrorCancelled
                        && error.code != NSURLErrorTimedOut
                        && error.code != NSURLErrorInternationalRoamingOff
                        && error.code != NSURLErrorDataNotAllowed
                        && error.code != NSURLErrorCannotFindHost
                        && error.code != NSURLErrorCannotConnectToHost) {
                        @synchronized (self.failedURLs) {
                            [self.failedURLs addObject:url];
                        }
                    }
                }
                else {
                    // 成功下载图片
                    if ((options & SDWebImageRetryFailed)) {
                        // 是重新下载的，移除在失败队列的url
                        @synchronized (self.failedURLs) {
                            [self.failedURLs removeObject:url];
                        }
                    }
                    // 是否要缓存在disk上
                    BOOL cacheOnDisk = !(options & SDWebImageCacheMemoryOnly);

                    if (options & SDWebImageRefreshCached && image && !downloadedImage) {
                        // Image refresh hit the NSURLCache cache, do not call the completion block
                        // 这种是什么情况呢？反正就是没有调用block
                    }
                    else if (downloadedImage && (!downloadedImage.images || (options & SDWebImageTransformAnimatedImage)) && [self.delegate respondsToSelector:@selector(imageManager:transformDownloadedImage:withURL:)]) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            UIImage *transformedImage = [self.delegate imageManager:self transformDownloadedImage:downloadedImage withURL:url];

                            if (transformedImage && finished) {
                                BOOL imageWasTransformed = ![transformedImage isEqual:downloadedImage];
                                [self.imageCache storeImage:transformedImage recalculateFromImage:imageWasTransformed imageData:(imageWasTransformed ? nil : data) forKey:key toDisk:cacheOnDisk];
                            }

                            dispatch_main_sync_safe(^{
                                if (strongOperation && !strongOperation.isCancelled) {
                                    completedBlock(transformedImage, nil, SDImageCacheTypeNone, finished, url);
                                }
                            });
                        });
                    }
                    else {
                        if (downloadedImage && finished) {
                            // 缓存图片
                            [self.imageCache storeImage:downloadedImage recalculateFromImage:NO imageData:data forKey:key toDisk:cacheOnDisk];
                        }

                        // 完成回调，回调到uiimageview上去了
                        
                        dispatch_main_sync_safe(^{
                            if (strongOperation && !strongOperation.isCancelled) {
                                completedBlock(downloadedImage, nil, SDImageCacheTypeNone, finished, url);
                            }
                        });
                    }
                }

                if (finished) {
                    // 完成了移除cachen operation 队列
                    @synchronized (self.runningOperations) {
                        if (strongOperation) {
                            [self.runningOperations removeObject:strongOperation];
                        }
                    }
                }
            }];
            operation.cancelBlock = ^{
                // 缓存的operation 里可以调用下载的operation取消
                [subOperation cancel];
                
                @synchronized (self.runningOperations) {
                    __strong __typeof(weakOperation) strongOperation = weakOperation;
                    if (strongOperation) {
                        // 移除operation
                        [self.runningOperations removeObject:strongOperation];
                    }
                }
            };
        }
        else if (image) {
            // 回调到主线程，先判断任务有没有被取消
            dispatch_main_sync_safe(^{
                __strong __typeof(weakOperation) strongOperation = weakOperation;
                if (strongOperation && !strongOperation.isCancelled) {
                    completedBlock(image, nil, cacheType, YES, url);
                }
            });
            // 移除cache operation
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
        }
        else {
            // Image not in cache and download disallowed by delegate
            // 图片不存在缓存里，并且代理不允许下载，回调block，移除操作
            dispatch_main_sync_safe(^{
                __strong __typeof(weakOperation) strongOperation = weakOperation;
                if (strongOperation && !weakOperation.isCancelled) {
                    completedBlock(nil, nil, SDImageCacheTypeNone, YES, url);
                }
            });
            @synchronized (self.runningOperations) {
                [self.runningOperations removeObject:operation];
            }
        }
    }];

    return operation;
}

- (void)cancelAll {
    @synchronized (self.runningOperations) {
        // 取出所有operation ，执行cancel操作
        NSArray *copiedOperations = [self.runningOperations copy];
        [copiedOperations makeObjectsPerformSelector:@selector(cancel)];
        [self.runningOperations removeObjectsInArray:copiedOperations];
    }
}

- (BOOL)isRunning {
    BOOL isRunning = NO;
    // 只要runningOperations 有operation，则认为isRunning = yes;
    @synchronized(self.runningOperations) {
        isRunning = (self.runningOperations.count > 0);
    }
    return isRunning;
}

// 缓存相关的操作。

// 根据url - > 得到key，有block执行自定义的block，没有则执行默认的absoluteString
- (NSString *)cacheKeyForURL:(NSURL *)url {
    if (!url) {
        return @"";
    }
    
    if (self.cacheKeyFilter) {
        return self.cacheKeyFilter(url);
    } else {
        return [url absoluteString];
    }
}

// 同步判断图片缓存是否存在，先检查内存，再检查disk
- (BOOL)cachedImageExistsForURL:(NSURL *)url {
    NSString *key = [self cacheKeyForURL:url];
    // 先检查内存有没有缓存，内存有缓存，直接返回yes
    if ([self.imageCache imageFromMemoryCacheForKey:key] != nil) return YES;
    
    // 再检查disk有没有缓存
    return [self.imageCache diskImageExistsWithKey:key];
}

// 同步检查disk上缓存图片是否存在
- (BOOL)diskImageExistsForURL:(NSURL *)url {
    NSString *key = [self cacheKeyForURL:url];
    // disk 缓存是否存在，根据key
    return [self.imageCache diskImageExistsWithKey:key];
}

// 异步判断图片缓存是否存在，先检查内存，再检查disk
- (void)cachedImageExistsForURL:(NSURL *)url
                     completion:(SDWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
    
    BOOL isInMemoryCache = ([self.imageCache imageFromMemoryCacheForKey:key] != nil);
    
    // 内存
    if (isInMemoryCache) {
        // making sure we call the completion block on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(YES);
            }
        });
        return;
    }
    
    // disk
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // the completion block of checkDiskCacheForImageWithKey:completion: is always called on the main queue, no need to further dispatch
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}

// disk上是否存在url对应的图片
- (void)diskImageExistsForURL:(NSURL *)url
                   completion:(SDWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
    
    // 查询disk缓存是否存在，回调completionBlock在主线程执行
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // the completion block of checkDiskCacheForImageWithKey:completion: is always called on the main queue, no need to further dispatch
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}

// 缓存图片，只有image 和 url 有值的时候，进行缓存,内存缓存和disk都缓存。
- (void)saveImageToCache:(UIImage *)image forURL:(NSURL *)url {
    if (image && url) {
        NSString *key = [self cacheKeyForURL:url];
        [self.imageCache storeImage:image forKey:key toDisk:YES];
    }
}

@end


@implementation SDWebImageCombinedOperation

- (void)setCancelBlock:(SDWebImageNoParamsBlock)cancelBlock {
    // check if the operation is already cancelled, then we just call the cancelBlock
    if (self.isCancelled) {
        if (cancelBlock) {
            cancelBlock();
        }
        _cancelBlock = nil; // don't forget to nil the cancelBlock, otherwise we will get crashes
    } else {
        _cancelBlock = [cancelBlock copy];
    }
}

- (void)cancel {
    self.cancelled = YES;
    if (self.cacheOperation) {
        [self.cacheOperation cancel];
        self.cacheOperation = nil;
    }
    if (self.cancelBlock) {
        self.cancelBlock();
        
        // TODO: this is a temporary fix to #809.
        // Until we can figure the exact cause of the crash, going with the ivar instead of the setter
//        self.cancelBlock = nil;
        _cancelBlock = nil;
    }
}

@end


// 废弃的函数
@implementation SDWebImageManager (Deprecated)

// deprecated method, uses the non deprecated method
// adapter for the completion block
- (id <SDWebImageOperation>)downloadWithURL:(NSURL *)url options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedWithFinishedBlock)completedBlock {
    return [self downloadImageWithURL:url
                              options:options
                             progress:progressBlock
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                if (completedBlock) {
                                    completedBlock(image, error, cacheType, finished);
                                }
                            }];
}

@end
