/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"

typedef NS_OPTIONS(NSUInteger, SDWebImageDownloaderOptions) {
    SDWebImageDownloaderLowPriority = 1 << 0,
    SDWebImageDownloaderProgressiveDownload = 1 << 1,

    /**
     * By default, request prevent the use of NSURLCache. With this flag, NSURLCache
     * is used with default policies.
     * 默认不使用NSURLCache
     */
    SDWebImageDownloaderUseNSURLCache = 1 << 2,

    /**
     * Call completion block with nil image/imageData if the image was read from NSURLCache
     * (to be combined with `SDWebImageDownloaderUseNSURLCache`).
     */

    SDWebImageDownloaderIgnoreCachedResponse = 1 << 3,
    /**
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     * 程序进入后台后继续下载，想系统申请得到额外时间，执行下载任务，若在规定时间内，没现在好，operation会取消下载
     */

    SDWebImageDownloaderContinueInBackground = 1 << 4,

    /**
     * Handles cookies stored in NSHTTPCookieStore by setting 
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    SDWebImageDownloaderHandleCookies = 1 << 5,

    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    SDWebImageDownloaderAllowInvalidSSLCertificates = 1 << 6,

    /**
     * Put the image in the high priority queue.
     */
    SDWebImageDownloaderHighPriority = 1 << 7,
};

typedef NS_ENUM(NSInteger, SDWebImageDownloaderExecutionOrder) {
    /**
     * Default value. All download operations will execute in queue style (first-in-first-out).
     * 下载队列的执行顺序，fifo，队列顺序，先进先出
     */
    SDWebImageDownloaderFIFOExecutionOrder,

    /**
     * All download operations will execute in stack style (last-in-first-out).
     * 下载队列的执行顺序，filo，栈顺序，先进后出
     */
    SDWebImageDownloaderLIFOExecutionOrder
};

// 引用外部的字符串，开始，结束的通知
extern NSString *const SDWebImageDownloadStartNotification;
extern NSString *const SDWebImageDownloadStopNotification;

// 进度的回调,接收到的size，总共的size
typedef void(^SDWebImageDownloaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);

// 下载完成的回调
typedef void(^SDWebImageDownloaderCompletedBlock)(UIImage *image, NSData *data, NSError *error, BOOL finished);

// 暂时不知道这个什么意思
typedef NSDictionary *(^SDWebImageDownloaderHeadersFilterBlock)(NSURL *url, NSDictionary *headers);

/**
 * Asynchronous downloader dedicated and optimized for image loading.
 */
@interface SDWebImageDownloader : NSObject

/**
 * Decompressing images that are downloaded and cached can improve performance but can consume lot of memory.
 * Defaults to YES. Set this to NO if you are experiencing a crash due to excessive memory consumption.
 * 牺牲内存，优化性能
 */
@property (assign, nonatomic) BOOL shouldDecompressImages;

// 最大下载任务的并发数
@property (assign, nonatomic) NSInteger maxConcurrentDownloads;

/**
 * Shows the current amount of downloads that still need to be downloaded
 * 当前正在还需要继续下载的任务
 */
@property (readonly, nonatomic) NSUInteger currentDownloadCount;


/**
 *  The timeout value (in seconds) for the download operation. Default: 15.0.
 *  超时时间 默认的是 ： 15.0
 */
@property (assign, nonatomic) NSTimeInterval downloadTimeout;


/**
 * Changes download operations execution order. Default value is `SDWebImageDownloaderFIFOExecutionOrder`.
 * 修改下载队列的执行顺序，默认的是fifo
 */
@property (assign, nonatomic) SDWebImageDownloaderExecutionOrder executionOrder;

/**
 *  Singleton method, returns the shared instance
 *
 *  @return global shared instance of downloader class
 *  单例方法，获取全局下载器
 */
+ (SDWebImageDownloader *)sharedDownloader;

/**
 *  Set the default URL credential to be set for request operations.
 * 需要研究这个类的作用，设计http的东西
 */
@property (strong, nonatomic) NSURLCredential *urlCredential;

/**
 * Set username
 * 设置用户名
 */
@property (strong, nonatomic) NSString *username;

/**
 * Set password
 * 设置密码
 */
@property (strong, nonatomic) NSString *password;

/**
 * Set filter to pick headers for downloading image HTTP request.
 *
 * This block will be invoked for each downloading image request, returned
 * NSDictionary will be used as headers in corresponding HTTP request.
 * 设置http header
 */
@property (nonatomic, copy) SDWebImageDownloaderHeadersFilterBlock headersFilter;

/**
 * Set a value for a HTTP header to be appended to each download HTTP request.
 *
 * @param value The value for the header field. Use `nil` value to remove the header.
 * @param field The name of the header field to set.
 * 设置http header
 */
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 * Returns the value of the specified HTTP header field.
 *
 * @return The value associated with the header field field, or `nil` if there is no corresponding header field.
 * 返回http header 的value
 */
- (NSString *)valueForHTTPHeaderField:(NSString *)field;

/**
 * Sets a subclass of `SDWebImageDownloaderOperation` as the default
 * `NSOperation` to be used each time SDWebImage constructs a request
 * operation to download an image.
 *
 * @param operationClass The subclass of `SDWebImageDownloaderOperation` to set 
 *        as default. Passing `nil` will revert to `SDWebImageDownloaderOperation`.
 * 设置下载任务的operation 的类，需要SDWebImageDownloaderOperation的子类，是nil的话，默认为SDWebImageDownloaderOperation
 */
- (void)setOperationClass:(Class)operationClass;

/**
 * Creates a SDWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 * 会通知代理，当完成的时候或者有错误的时候
 *
 * @see SDWebImageDownloaderDelegate
 *
 * @param url            The URL to the image to download
 * @param options        The options to be used for this download
 * @param progressBlock  A block called repeatedly while the image is downloading
 * @param completedBlock A block called once the download is completed.
 *                       If the download succeeded, the image parameter is set, in case of error,
 *                       error parameter is set with the error. The last parameter is always YES
 *                       if SDWebImageDownloaderProgressiveDownload isn't use. With the
 *                       SDWebImageDownloaderProgressiveDownload option, this block is called
 *                       repeatedly with the partial image object and the finished argument set to NO
 *                       before to be called a last time with the full image and finished argument
 *                       set to YES. In case of error, the finished argument is always YES.
 *
 * @return A cancellable SDWebImageOperation
 */
- (id <SDWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                         options:(SDWebImageDownloaderOptions)options
                                        progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                       completed:(SDWebImageDownloaderCompletedBlock)completedBlock;

/**
 * Sets the download queue suspension state
 * 挂起队列里的所有操作。
 */
- (void)setSuspended:(BOOL)suspended;

/**
 * Cancels all download operations in the queue
 * 取消队列里的所有下载操作
 */
- (void)cancelAllDownloads;

@end
