/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloaderOperation.h"
#import "SDWebImageDecoder.h"
#import "UIImage+MultiFormat.h"
#import <ImageIO/ImageIO.h>
#import "SDWebImageManager.h"

// 借个通知的名称
NSString *const SDWebImageDownloadStartNotification = @"SDWebImageDownloadStartNotification";
NSString *const SDWebImageDownloadReceiveResponseNotification = @"SDWebImageDownloadReceiveResponseNotification";
NSString *const SDWebImageDownloadStopNotification = @"SDWebImageDownloadStopNotification";
NSString *const SDWebImageDownloadFinishNotification = @"SDWebImageDownloadFinishNotification";

@interface SDWebImageDownloaderOperation ()

// 3个回调
@property (copy, nonatomic) SDWebImageDownloaderProgressBlock progressBlock;
@property (copy, nonatomic) SDWebImageDownloaderCompletedBlock completedBlock;
@property (copy, nonatomic) SDWebImageNoParamsBlock cancelBlock;

// 是否正在执行
@property (assign, nonatomic, getter = isExecuting) BOOL executing;

// 下载是否完成
@property (assign, nonatomic, getter = isFinished) BOOL finished;

// 图片的二进制数据
@property (strong, nonatomic) NSMutableData *imageData;

// 需要研究这个weak的用法，为了什么，是外部传进的session。SDWebImageDownloader, 传进来的session
// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run
// the task associated with this operation
@property (weak, nonatomic) NSURLSession *unownedSession;


// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
// 如果外部传进来的session为空的话，属于自己内部的一个sesson
@property (strong, nonatomic) NSURLSession *ownedSession;

// 下载图片的task
@property (strong, nonatomic, readwrite) NSURLSessionTask *dataTask;

// 可能指执行这个operation 的线程。
@property (strong, atomic) NSThread *thread;

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
// 后天下载的任务的Identifier，标识
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
#endif

@end

@implementation SDWebImageDownloaderOperation {
    // 图片的宽，高
    size_t width, height;
    
    // 图片的方向
    UIImageOrientation orientation;
    
    // 是否是从http 系统的缓存里获取的
    BOOL responseFromCached;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

// 废弃的方法
- (id)initWithRequest:(NSURLRequest *)request
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(SDWebImageNoParamsBlock)cancelBlock {

    return [self initWithRequest:request
                       inSession:nil
                         options:options
                        progress:progressBlock
                       completed:completedBlock
                       cancelled:cancelBlock];
}

// 初始化下载的operation
- (id)initWithRequest:(NSURLRequest *)request
            inSession:(NSURLSession *)session
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(SDWebImageNoParamsBlock)cancelBlock {
    if ((self = [super init])) {
        _request = request;
        _shouldDecompressImages = YES;
        _options = options;
        _progressBlock = [progressBlock copy];
        _completedBlock = [completedBlock copy];
        _cancelBlock = [cancelBlock copy];
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
        _unownedSession = session;
        // 默认是从缓存里去的状态，知道这个代理方法调用，再次设置状态
        responseFromCached = YES; // Initially wrong until `- URLSession:dataTask:willCacheResponse:completionHandler: is called or not called
    }
    return self;
}
// 重写了start 方法，没有重写main 方法
- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            // 盘点任务有没有被取消，可能一开始放在队列了，取出来执行的时候，发现用户取消下载操作，则设置finish状态，充值属性，成员变量
            self.finished = YES;
            [self reset];
            return;
        }

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
        // iOS 4.0 以上的，后台可以继续执行下载任务
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
        if (hasApplication && [self shouldContinueWhenAppEntersBackground]) {
            // 若果设置了进入后台继续下载的选项
            __weak __typeof__ (self) wself = self;
            UIApplication * app = [UIApplicationClass performSelector:@selector(sharedApplication)];
            // 这个方法需要研究
            self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
                __strong __typeof (wself) sself = wself;

                if (sself) {
                    // 进入后台后，时间到了，则执行cancel操作
                    [sself cancel];
                    
                    // 结束后台任务
                    [app endBackgroundTask:sself.backgroundTaskId];
                    sself.backgroundTaskId = UIBackgroundTaskInvalid;
                }
            }];
        }
#endif
        NSURLSession *session = self.unownedSession;
        // 如果外部的session为空，则自己建一个session，可能是为了兼容老接口
        if (!self.unownedSession) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            
            // 超时时间为15.0s
            sessionConfig.timeoutIntervalForRequest = 15;
            
            /**
             *  Create the session for this task
             *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
             *  method calls and completion handler calls.
             */
            
            // 自己内部建了一个session，用来下载图片
            self.ownedSession = [NSURLSession sessionWithConfiguration:sessionConfig
                                                              delegate:self
                                                         delegateQueue:nil];
            session = self.ownedSession;
        }
        
        self.dataTask = [session dataTaskWithRequest:self.request];
        self.executing = YES;
        self.thread = [NSThread currentThread];
        NSLog(@"SDWebImageDownloaderOperation = %@",self.thread);
    }
    
    // 开始下载
    [self.dataTask resume];

    if (self.dataTask) {
        // 先会掉一下这个block，什么作用呢
        if (self.progressBlock) {
            self.progressBlock(0, NSURLResponseUnknownLength);
        }
        // 在主线程里post 一个请求，开始下载
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStartNotification object:self];
        });
    }
    else {
        // 现在task为nil，则回调completedBlock，报错误
        if (self.completedBlock) {
            self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Connection can't be initialized"}], YES);
        }
    }

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        UIApplication * app = [UIApplication performSelector:@selector(sharedApplication)];
        [app endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
#endif
}

// 取消下载
- (void)cancel {
    @synchronized (self) {
        if (self.thread) {
            // 在那个operation 的thread 执行方法，一般这个cancel'的调用者是在主线程，所以切换线程
            [self performSelector:@selector(cancelInternalAndStop) onThread:self.thread withObject:nil waitUntilDone:NO];
        }
        else {
            [self cancelInternal];
        }
    }
}

- (void)cancelInternalAndStop {
    if (self.isFinished) return;
    [self cancelInternal];
}

- (void)cancelInternal {
    if (self.isFinished) return;
    [super cancel];
    
    // 回调cacel的block
    if (self.cancelBlock) self.cancelBlock();

    if (self.dataTask) {
        // 取消下载任务
        [self.dataTask cancel];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 发出取消通知
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:self];
        });

        // As we cancelled the connection, its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        // 设置状态,executing 设置为no，finished设置为yes。
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }

    [self reset];
}

// 表示下载完成，设置各个状体
- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

// 重置状态
- (void)reset {
    self.cancelBlock = nil;
    self.completedBlock = nil;
    self.progressBlock = nil;
    self.dataTask = nil;
    self.imageData = nil;
    self.thread = nil;
    if (self.ownedSession) {
        // 如果是自己的operation，取消所有下载的task
        [self.ownedSession invalidateAndCancel];
        self.ownedSession = nil;
    }
}

// 设置完成的状态
- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

// 设置执行的状态
- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

// 重写这个方法，表示是异步执行
- (BOOL)isConcurrent {
    return YES;
}

#pragma mark NSURLSessionDataDelegate

// 这个队列执行的线程跟执行operation 所在的线程，不是同一个线程
// 接收到请求头
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    //'304 Not Modified' is an exceptional one
    if (![response respondsToSelector:@selector(statusCode)] || ([((NSHTTPURLResponse *)response) statusCode] < 400 && [((NSHTTPURLResponse *)response) statusCode] != 304)) {
        // 设置文件的大小，即期望下载的大小
        NSInteger expected = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
        self.expectedSize = expected;
        
        // 先会调用下block
        if (self.progressBlock) {
            self.progressBlock(0, expected);
        }
        
        // 创建data
        self.imageData = [[NSMutableData alloc] initWithCapacity:expected];
        
        // http 相应
        self.response = response;
        
        // 在主线程里post 通知
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadReceiveResponseNotification object:self];
        });
    }
    else {
        // 缓存文件没有变化，就完成下载了
        NSUInteger code = [((NSHTTPURLResponse *)response) statusCode];
        
        //This is the case when server returns '304 Not Modified'. It means that remote image is not changed.
        //In case of 304 we need just cancel the operation and return cached image from the cache.
        if (code == 304) {
            // 表示资源文件，没被修改过，就取消
            [self cancelInternal];
        } else {
            // 取消下载
            [self.dataTask cancel];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            // 通知停止下载
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:self];
        });
        
        if (self.completedBlock) {
            // 调用completedBlock ，304
            self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:[((NSHTTPURLResponse *)response) statusCode] userInfo:nil], YES);
        }
        [self done];
    }
    
    // 继续接收数据
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

// 接受图片数据的回调，可能调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    // 添加二进制数据
    [self.imageData appendData:data];

    // 渐进式下载的处理
    if ((self.options & SDWebImageDownloaderProgressiveDownload) && self.expectedSize > 0 && self.completedBlock) {
        // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
        // Thanks to the author @Nyx0uf

        // Get the total bytes downloaded
        const NSInteger totalSize = self.imageData.length;

        // Update the data source, we must pass ALL the data, not just the new bytes
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.imageData, NULL);

        if (width + height == 0) {
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            if (properties) {
                NSInteger orientationValue = -1;
                CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &height);
                val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &width);
                val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
                if (val) CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
                CFRelease(properties);

                // When we draw to Core Graphics, we lose orientation information,
                // which means the image below born of initWithCGIImage will be
                // oriented incorrectly sometimes. (Unlike the image born of initWithData
                // in didCompleteWithError.) So save it here and pass it on later.
                orientation = [[self class] orientationFromPropertyValue:(orientationValue == -1 ? 1 : orientationValue)];
            }

        }

        if (width + height > 0 && totalSize < self.expectedSize) {
            // Create the image
            CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);

#ifdef TARGET_OS_IPHONE
            // Workaround for iOS anamorphic image
            if (partialImageRef) {
                const size_t partialHeight = CGImageGetHeight(partialImageRef);
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
                CGColorSpaceRelease(colorSpace);
                if (bmContext) {
                    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = partialHeight}, partialImageRef);
                    CGImageRelease(partialImageRef);
                    partialImageRef = CGBitmapContextCreateImage(bmContext);
                    CGContextRelease(bmContext);
                }
                else {
                    CGImageRelease(partialImageRef);
                    partialImageRef = nil;
                }
            }
#endif

            if (partialImageRef) {
                UIImage *image = [UIImage imageWithCGImage:partialImageRef scale:1 orientation:orientation];
                NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
                UIImage *scaledImage = [self scaledImageForKey:key image:image];
                if (self.shouldDecompressImages) {
                    image = [UIImage decodedImageWithImage:scaledImage];
                }
                else {
                    image = scaledImage;
                }
                CGImageRelease(partialImageRef);
                dispatch_main_sync_safe(^{
                    if (self.completedBlock) {
                        self.completedBlock(image, nil, nil, NO);
                    }
                });
            }
        }

        CFRelease(imageSource);
    }

    // 调动回调函数
    if (self.progressBlock) {
        self.progressBlock(self.imageData.length, self.expectedSize);
    }
}

// 询问是可以否缓存数据，在下载完成之后调用
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {

    // 如果这个方法被调用了，说明是从网上下载的，并不是从缓存读取的
    responseFromCached = NO; // If this method is called, it means the response wasn't read from cache
    NSCachedURLResponse *cachedResponse = proposedResponse;

    if (self.request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
        // 不缓存
        // Prevents caching of responses
        cachedResponse = nil;
    }
    if (completionHandler) {
        completionHandler(cachedResponse);
    }
}

#pragma mark NSURLSessionTaskDelegate

// 下载完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    @synchronized(self) {
        self.thread = nil;
        self.dataTask = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // 停止下载的通知
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:self];
            if (!error) {
                // 下载完成的通知
                [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadFinishNotification object:self];
            }
        });
    }
    
    if (error) {
        // 是有失败的完成，则回调失败的block
        if (self.completedBlock) {
            self.completedBlock(nil, nil, error, YES);
        }
    } else {
        // 正常的下载完成
        SDWebImageDownloaderCompletedBlock completionBlock = self.completedBlock;
        
        // 查询本地缓存，是否是从本地缓存加载的，没有的话，说明是从服务器下载的
        if (![[NSURLCache sharedURLCache] cachedResponseForRequest:_request]) {
            // 不是从缓存里取出来的
            responseFromCached = NO;
        }
        
        if (completionBlock) {
            if (self.options & SDWebImageDownloaderIgnoreCachedResponse && responseFromCached) {
                // 指定不从缓存中读取，但实际又是从缓存中读取的，那image，imaedata就是nil
                completionBlock(nil, nil, nil, YES);
            } else if (self.imageData) {
                // 有数据，生成图片
                UIImage *image = [UIImage sd_imageWithData:self.imageData];
                NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
                image = [self scaledImageForKey:key image:image];
                NSLog(@"image = %@, thread = %@",image,[NSThread currentThread]);
                // Do not force decoding animated GIFs
                if (!image.images) {
                    if (self.shouldDecompressImages) {
                        image = [UIImage decodedImageWithImage:image];
                    }
                }
                if (CGSizeEqualToSize(image.size, CGSizeZero)) {
                    // 判断图片的尺寸，0像素
                    completionBlock(nil, nil, [NSError errorWithDomain:SDWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Downloaded image has 0 pixels"}], YES);
                }
                else {
                    // 完成的回调
                    completionBlock(image, self.imageData, nil, YES);
                }
            } else {
                // imagedata 为空的回调，下载失败
                completionBlock(nil, nil, [NSError errorWithDomain:SDWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Image data is nil"}], YES);
            }
        }
    }
    
    // completionBlock 置空
    self.completionBlock = nil;
    // 设置完成状态
    [self done];
}

// 应该跟https相关，需要研究，暂时跳过吧
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if (!(self.options & SDWebImageDownloaderAllowInvalidSSLCertificates)) {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        } else {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            disposition = NSURLSessionAuthChallengeUseCredential;
        }
    } else {
        if ([challenge previousFailureCount] == 0) {
            if (self.credential) {
                credential = self.credential;
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
            }
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

#pragma mark Helper methods

+ (UIImageOrientation)orientationFromPropertyValue:(NSInteger)value {
    switch (value) {
        case 1:
            return UIImageOrientationUp;
        case 3:
            return UIImageOrientationDown;
        case 8:
            return UIImageOrientationLeft;
        case 6:
            return UIImageOrientationRight;
        case 2:
            return UIImageOrientationUpMirrored;
        case 4:
            return UIImageOrientationDownMirrored;
        case 5:
            return UIImageOrientationLeftMirrored;
        case 7:
            return UIImageOrientationRightMirrored;
        default:
            return UIImageOrientationUp;
    }
}

- (UIImage *)scaledImageForKey:(NSString *)key image:(UIImage *)image {
    return SDScaledImageForKey(key, image);
}

// 进入后台后继续下载
- (BOOL)shouldContinueWhenAppEntersBackground {
    return self.options & SDWebImageDownloaderContinueInBackground;
}

@end
