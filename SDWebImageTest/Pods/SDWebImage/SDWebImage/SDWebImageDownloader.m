/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloader.h"
#import "SDWebImageDownloaderOperation.h"
#import <ImageIO/ImageIO.h>

// 回调的两个key，progress,complete的两个block的两个回调的key
static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completed";

@interface SDWebImageDownloader () <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

// 下载队列
@property (strong, nonatomic) NSOperationQueue *downloadQueue;

// 最后一个operation
@property (weak, nonatomic) NSOperation *lastAddedOperation;

// operation class
@property (assign, nonatomic) Class operationClass;

// 回调
@property (strong, nonatomic) NSMutableDictionary *URLCallbacks;

// http header 头
@property (strong, nonatomic) NSMutableDictionary *HTTPHeaders;

// This queue is used to serialize the handling of the network responses of all the download operation in a single queue
// GCD 的栅栏
@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t barrierQueue;

// The session in which data tasks will run
// NSURLSession session
@property (strong, nonatomic) NSURLSession *session;

@end

@implementation SDWebImageDownloader

+ (void)initialize {
    // Bind SDNetworkActivityIndicator if available (download it here: http://github.com/rs/SDNetworkActivityIndicator )
    // To use it, just add #import "SDNetworkActivityIndicator.h" in addition to the SDWebImage import
    // 如果项目中有SDNetworkActivityIndicator这个类，就绑定到这个类
    if (NSClassFromString(@"SDNetworkActivityIndicator")) {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id activityIndicator = [NSClassFromString(@"SDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
#pragma clang diagnostic pop

        // Remove observer in case it was previously added.
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStopNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:SDWebImageDownloadStopNotification object:nil];
    }
}

// 获取全局对象
+ (SDWebImageDownloader *)sharedDownloader {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init {
    if ((self = [super init])) {
        // 默认是SDWebImageDownloaderOperation class
        _operationClass = [SDWebImageDownloaderOperation class];
        // 默认是yes
        _shouldDecompressImages = YES;
        // 默认是先进先出顺序
        _executionOrder = SDWebImageDownloaderFIFOExecutionOrder;
        // 创建现在队列
        _downloadQueue = [NSOperationQueue new];
        // 同一时刻可以执行最大的任务数
        _downloadQueue.maxConcurrentOperationCount = 6;
        // 存放回调的数组
        _URLCallbacks = [NSMutableDictionary new];
        // 设置请求头
#ifdef SD_WEBP
        _HTTPHeaders = [@{@"Accept": @"image/webp,image/*;q=0.8"} mutableCopy];
#else
        _HTTPHeaders = [@{@"Accept": @"image/*;q=0.8"} mutableCopy];
#endif
        // GCD，并行队列
        _barrierQueue = dispatch_queue_create("com.hackemist.SDWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        // 默认超时时间是15.0
        _downloadTimeout = 15.0;

        //NSURLSessionConfiguration configuration配置,使用默认配置
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 超时时间为 15s
        sessionConfig.timeoutIntervalForRequest = _downloadTimeout;

        /**
         *  Create the session for this task
         *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
         *  method calls and completion handler calls.
         */
        self.session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                     delegate:self
                                                delegateQueue:nil];
    }
    return self;
}

// 对下下载器的一些设置和设置获取
// 设置http 头部
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if (value) {
        self.HTTPHeaders[field] = value;
    }
    else {
        [self.HTTPHeaders removeObjectForKey:field];
    }
}

// 返回某个字段http 头部
- (NSString *)valueForHTTPHeaderField:(NSString *)field {
    return self.HTTPHeaders[field];
}

// 设置下载队列的最大并发数
- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

// 当前还在队列里等待下载的个数
- (NSUInteger)currentDownloadCount {
    return _downloadQueue.operationCount;
}

// 获取下载队列最大的并发数
- (NSInteger)maxConcurrentDownloads {
    return _downloadQueue.maxConcurrentOperationCount;
}

// 设置operationClass，默认是SDWebImageDownloaderOperation
- (void)setOperationClass:(Class)operationClass {
    _operationClass = operationClass ?: [SDWebImageDownloaderOperation class];
}



// 核心操作，下载图片
- (id <SDWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(SDWebImageDownloaderOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageDownloaderCompletedBlock)completedBlock {
    __block SDWebImageDownloaderOperation *operation;
    __weak __typeof(self)wself = self;

    [self addProgressCallback:progressBlock completedBlock:completedBlock forURL:url createCallback:^{
        // 根据url ，添加progress，complete block 之后的回调
        // 如果downloadTimeout为0，则重新设为默认的15
        NSTimeInterval timeoutInterval = wself.downloadTimeout;
        if (timeoutInterval == 0.0) {
            timeoutInterval = 15.0;
        }

        // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests if told otherwise
        // 一些http request的设置
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:(options & SDWebImageDownloaderUseNSURLCache ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData) timeoutInterval:timeoutInterval];
        request.HTTPShouldHandleCookies = (options & SDWebImageDownloaderHandleCookies);
        request.HTTPShouldUsePipelining = YES;
        // 让用户重新设置http头
        if (wself.headersFilter) {
            request.allHTTPHeaderFields = wself.headersFilter(url, [wself.HTTPHeaders copy]);
        }
        else {
            request.allHTTPHeaderFields = wself.HTTPHeaders;
        }
        
        // 创建下载的operation
        operation = [[wself.operationClass alloc] initWithRequest:request
                                                        inSession:self.session
                                                          options:options
                                                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                             SDWebImageDownloader *sself = wself;
                                                             if (!sself) return;
                                                             __block NSArray *callbacksForURL;
                                                             // 同步执行，根据url 找出之前设置回调的数组
                                                             dispatch_sync(sself.barrierQueue, ^{
                                                                 callbacksForURL = [sself.URLCallbacks[url] copy];
                                                             });
                                                             // 遍历回调的数组，字典中取出ProgressBlock
                                                             for (NSDictionary *callbacks in callbacksForURL) {
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     SDWebImageDownloaderProgressBlock callback = callbacks[kProgressCallbackKey];
                                                                     if (callback) callback(receivedSize, expectedSize);
                                                                 });
                                                             }
                                                         }
                                                        completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                            SDWebImageDownloader *sself = wself;
                                                            if (!sself) return;
                                                            __block NSArray *callbacksForURL;
                                                            // 同步执行，根据url 找出之前设置回调的数组
                                                            dispatch_barrier_sync(sself.barrierQueue, ^{
                                                                callbacksForURL = [sself.URLCallbacks[url] copy];
                                                                if (finished) {
                                                                    [sself.URLCallbacks removeObjectForKey:url];
                                                                }
                                                            });
                                                            // 遍历回调的数组，字典中取出CompletedBlock
                                                            for (NSDictionary *callbacks in callbacksForURL) {
                                                                SDWebImageDownloaderCompletedBlock callback = callbacks[kCompletedCallbackKey];
                                                                if (callback) callback(image, data, error, finished);
                                                            }
                                                        }
                                                        cancelled:^{
                                                            SDWebImageDownloader *sself = wself;
                                                            if (!sself) return;
                                                            dispatch_barrier_async(sself.barrierQueue, ^{
                                                                [sself.URLCallbacks removeObjectForKey:url];
                                                            });
                                                        }];
        
        operation.shouldDecompressImages = wself.shouldDecompressImages;
        
        // 这块暂时需要研究，跟http相关
        if (wself.urlCredential) {
            operation.credential = wself.urlCredential;
        } else if (wself.username && wself.password) {
            operation.credential = [NSURLCredential credentialWithUser:wself.username password:wself.password persistence:NSURLCredentialPersistenceForSession];
        }
        
        // 设置现在操作的优先级
        if (options & SDWebImageDownloaderHighPriority) {
            operation.queuePriority = NSOperationQueuePriorityHigh;
        } else if (options & SDWebImageDownloaderLowPriority) {
            operation.queuePriority = NSOperationQueuePriorityLow;
        }

        // 下载队列添加操作
        [wself.downloadQueue addOperation:operation];
        
        
        if (wself.executionOrder == SDWebImageDownloaderLIFOExecutionOrder) {
            // Emulate LIFO execution order by systematically adding new operations as last operation's dependency
            // 模拟先进后出的操作，最后一个操作依赖于当前的，则当前的先执行，再把当前的设置为最后一个operation
            // 但是感觉没什么用啊
            [wself.lastAddedOperation addDependency:operation];
            wself.lastAddedOperation = operation;
        }
    }];

    return operation;
}

- (void)addProgressCallback:(SDWebImageDownloaderProgressBlock)progressBlock completedBlock:(SDWebImageDownloaderCompletedBlock)completedBlock forURL:(NSURL *)url createCallback:(SDWebImageNoParamsBlock)createCallback {
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    // url 不能为空，如果为空的话，立即回调完成的block
    if (url == nil) {
        if (completedBlock != nil) {
            completedBlock(nil, nil, nil, NO);
        }
        return;
    }

    // 线程安全吧，而且是同步的
    dispatch_barrier_sync(self.barrierQueue, ^{
        BOOL first = NO;
        if (!self.URLCallbacks[url]) {
            // 根据url，在数组里添加意一项，添加的对象是一个数组,数组里添加一个字典，字典包含
            // progress，complete两个回调
            self.URLCallbacks[url] = [NSMutableArray new];
            first = YES;
        }

        // Handle single download of simultaneous download request for the same URL
        NSMutableArray *callbacksForURL = self.URLCallbacks[url];
        NSMutableDictionary *callbacks = [NSMutableDictionary new];
        if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
        if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
        [callbacksForURL addObject:callbacks];
        self.URLCallbacks[url] = callbacksForURL;

        if (first) {
            // 每个url第一次进来，回调下，传进来的block
            createCallback();
        }
    });
}

// 暂停队列
- (void)setSuspended:(BOOL)suspended {
    [self.downloadQueue setSuspended:suspended];
}

// 取消所有下载
- (void)cancelAllDownloads {
    [self.downloadQueue cancelAllOperations];
}

#pragma mark Helper methods

- (SDWebImageDownloaderOperation *)operationWithTask:(NSURLSessionTask *)task {
    // 自定义的operation 里有task，遍历operations，找出跟task对应的operation
    SDWebImageDownloaderOperation *returnOperation = nil;
    for (SDWebImageDownloaderOperation *operation in self.downloadQueue.operations) {
        if (operation.dataTask.taskIdentifier == task.taskIdentifier) {
            returnOperation = operation;
            break;
        }
    }
    return returnOperation;
}


#pragma mark NSURLSessionDataDelegate

//  代理方法

// 这些代理方法需要研究下。每个下载开始时，会接收到头部数据，然后控制可不可以继续下载
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];

    [dataOperation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

// 接受到数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {

    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];

    [dataOperation URLSession:session dataTask:dataTask didReceiveData:data];
}

// 这些代理方法需要研究下
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:dataTask];

    [dataOperation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
}

#pragma mark NSURLSessionTaskDelegate

// 代理方法
// 图片下载完成的通知
// 错误指的是客户端的错误，包括无法解析域名，不能连到主机等错误
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];

    [dataOperation URLSession:session task:task didCompleteWithError:error];
}

// https相关的状态
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    // Identify the operation that runs this task and pass it the delegate method
    SDWebImageDownloaderOperation *dataOperation = [self operationWithTask:task];

    [dataOperation URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
}

- (void)dealloc {
    // session 取消
    [self.session invalidateAndCancel];
    self.session = nil;
    
    // 下载队列取消下载
    [self.downloadQueue cancelAllOperations];
    SDDispatchQueueRelease(_barrierQueue);
}

@end
