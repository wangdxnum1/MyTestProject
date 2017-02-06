/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageDownloader.h"
#import "SDWebImageOperation.h"

// 引用外部文件的通知
// 开始下载的通知
extern NSString *const SDWebImageDownloadStartNotification;

// 接收到数据的通知
extern NSString *const SDWebImageDownloadReceiveResponseNotification;

// 暂停的通知
extern NSString *const SDWebImageDownloadStopNotification;

// 完成的通知
extern NSString *const SDWebImageDownloadFinishNotification;

// 自定义下载的操作类，遵循3个协议，一个自定义的协议，支持cancel接口
@interface SDWebImageDownloaderOperation : NSOperation <SDWebImageOperation, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

/**
 * The request used by the operation's task.
 * request
 */
@property (strong, nonatomic, readonly) NSURLRequest *request;

/**
 * The operation's task
 * task
 */
@property (strong, nonatomic, readonly) NSURLSessionTask *dataTask;

// 是否解压，默认是yes
@property (assign, nonatomic) BOOL shouldDecompressImages;

/**
 *  Was used to determine whether the URL connection should consult the credential storage for authenticating the connection.
 *  @deprecated Not used for a couple of versions
 * 已经废弃的属性，不做任何事，兼容旧版本
 */
@property (nonatomic, assign) BOOL shouldUseCredentialStorage __deprecated_msg("Property deprecated. Does nothing. Kept only for backwards compatibility");

/**
 * The credential used for authentication challenges in `-connection:didReceiveAuthenticationChallenge:`.
 *
 * This will be overridden by any shared credentials that exist for the username or password of the request URL, if present.
 * 这个概念需要研究
 */
@property (nonatomic, strong) NSURLCredential *credential;

/**
 * The SDWebImageDownloaderOptions for the receiver.
 * 下载的请求选项
 */
@property (assign, nonatomic, readonly) SDWebImageDownloaderOptions options;

/**
 * The expected size of data.
 * 期望的size，服务器上文件的大小，需要下载图片的大小
 */
@property (assign, nonatomic) NSInteger expectedSize;

/**
 * The response returned by the operation's connection.
 * http 请求返回的response
 */
@property (strong, nonatomic) NSURLResponse *response;

/**
 *  Initializes a `SDWebImageDownloaderOperation` object
 *
 *  @see SDWebImageDownloaderOperation
 *
 *  @param request        the URL request
 *  @param session        the URL session in which this operation will run
 *  @param options        downloader options
 *  @param progressBlock  the block executed when a new chunk of data arrives. 
 *                        @note the progress block is executed on a background queue
 *  @param completedBlock the block executed when the download is done. 
 *                        @note the completed block is executed on the main queue for success. If errors are found, there is a chance the block will be executed on a background queue
 *  @param cancelBlock    the block executed if the download (operation) is cancelled
 *
 *  @return the initialized instance
 *  下载操作下载图片的api，request，session，下载选项，3个回调，progressBlock，completedBlock，cancelBlock
 */
- (id)initWithRequest:(NSURLRequest *)request
            inSession:(NSURLSession *)session
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(SDWebImageNoParamsBlock)cancelBlock;

/**
 *  Initializes a `SDWebImageDownloaderOperation` object
 *
 *  @see SDWebImageDownloaderOperation
 *
 *  @param request        the URL request
 *  @param options        downloader options
 *  @param progressBlock  the block executed when a new chunk of data arrives.
 *                        @note the progress block is executed on a background queue
 *  @param completedBlock the block executed when the download is done.
 *                        @note the completed block is executed on the main queue for success. If errors are found, there is a chance the block will be executed on a background queue
 *  @param cancelBlock    the block executed if the download (operation) is cancelled
 *
 *  @return the initialized instance. The operation will run in a separate session created for this operation
 *  废弃的接口
 */
- (id)initWithRequest:(NSURLRequest *)request
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(SDWebImageNoParamsBlock)cancelBlock
__deprecated_msg("Method deprecated. Use `initWithRequest:inSession:options:progress:completed:cancelled`");

@end
