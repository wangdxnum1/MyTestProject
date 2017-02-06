/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+WebCache.h"
#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"

static char imageURLKey;
static char TAG_ACTIVITY_INDICATOR;
static char TAG_ACTIVITY_STYLE;
static char TAG_ACTIVITY_SHOW;

@implementation UIImageView (WebCache)

- (void)sd_setImageWithURL:(NSURL *)url {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(NSURL *)url completed:(SDWebImageCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletionBlock)completedBlock {
    
    // 取消之前operation 的下载任务
    [self sd_cancelCurrentImageLoad];
    
    // 保存url,url 与imageView关联
    objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // 不是延迟加载PlaceholderImage的话，则立马设置占位图片
    if (!(options & SDWebImageDelayPlaceholder)) {
        dispatch_main_async_safe(^{
            self.image = placeholder;
        });
    }
    
    if (url) {

        // check if activityView is enabled or not
        // 如果需要显示菊花，则添加菊花并显示
        if ([self showActivityIndicatorView]) {
            [self addActivityIndicator];
        }

        __weak __typeof(self)wself = self;
        id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            // 成功之后的回调，先移除菊花
            [wself removeActivityIndicator];
            if (!wself) return;
            
            dispatch_main_sync_safe(^{
                if (!wself) return;
                
                if (image && (options & SDWebImageAvoidAutoSetImage) && completedBlock)
                {
                    // 有图片，并且不自动设置image，和有completedBlock
                    completedBlock(image, error, cacheType, url);
                    return;
                }
                else if (image) {
                    // 设置显示的图片，让imageview 立马重新绘制
                    wself.image = image;
                    [wself setNeedsLayout];
                } else {
                    // 设置延迟显示的展位图片，也就说这张展位图一定要在下载完成之后，或者从缓存中读到了再设置占位图片
                    if ((options & SDWebImageDelayPlaceholder)) {
                        wself.image = placeholder;
                        [wself setNeedsLayout];
                    }
                }
                if (completedBlock && finished) {
                    // 回调completedBlock
                    completedBlock(image, error, cacheType, url);
                }
            });
        }];
        
        // UIImageViewImageLoad 根据这个key，缓存operation，也就是说，不同的url，key是一样的
        // 而不是以url作为key
        [self sd_setImageLoadOperation:operation forKey:@"UIImageViewImageLoad"];
        
    } else {
        // url 为空的话，则回到主线程，首先移除菊花，回调completedBlock
        dispatch_main_async_safe(^{
            [self removeActivityIndicator];
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:SDWebImageErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
                completedBlock(nil, error, SDImageCacheTypeNone, url);
            }
        });
    }
}

- (void)sd_setImageWithPreviousCachedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletionBlock)completedBlock {
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
    UIImage *lastPreviousCachedImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:key];
    
    [self sd_setImageWithURL:url placeholderImage:lastPreviousCachedImage ?: placeholder options:options progress:progressBlock completed:completedBlock];    
}

// 获取imageView绑定的url
- (NSURL *)sd_imageURL {
    return objc_getAssociatedObject(self, &imageURLKey);
}

- (void)sd_setAnimationImagesWithURLs:(NSArray *)arrayOfURLs {
    [self sd_cancelCurrentAnimationImagesLoad];
    __weak __typeof(self)wself = self;

    NSMutableArray *operationsArray = [[NSMutableArray alloc] init];

    for (NSURL *logoImageURL in arrayOfURLs) {
        id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadImageWithURL:logoImageURL options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                __strong UIImageView *sself = wself;
                [sself stopAnimating];
                if (sself && image) {
                    NSMutableArray *currentImages = [[sself animationImages] mutableCopy];
                    if (!currentImages) {
                        currentImages = [[NSMutableArray alloc] init];
                    }
                    [currentImages addObject:image];

                    sself.animationImages = currentImages;
                    [sself setNeedsLayout];
                }
                [sself startAnimating];
            });
        }];
        [operationsArray addObject:operation];
    }

    [self sd_setImageLoadOperation:[NSArray arrayWithArray:operationsArray] forKey:@"UIImageViewAnimationImages"];
}

- (void)sd_cancelCurrentImageLoad {
    [self sd_cancelImageLoadOperationWithKey:@"UIImageViewImageLoad"];
}

- (void)sd_cancelCurrentAnimationImagesLoad {
    [self sd_cancelImageLoadOperationWithKey:@"UIImageViewAnimationImages"];
}


#pragma mark -
// 用runtime 给imageview 增加开个属性

// UIActivityIndicatorView 的get & set 方法
- (UIActivityIndicatorView *)activityIndicator {
    return (UIActivityIndicatorView *)objc_getAssociatedObject(self, &TAG_ACTIVITY_INDICATOR);
}

- (void)setActivityIndicator:(UIActivityIndicatorView *)activityIndicator {
    objc_setAssociatedObject(self, &TAG_ACTIVITY_INDICATOR, activityIndicator, OBJC_ASSOCIATION_RETAIN);
}

// 是否显示UIActivityIndicatorView 的 get & set 方法
- (void)setShowActivityIndicatorView:(BOOL)show{
    objc_setAssociatedObject(self, &TAG_ACTIVITY_SHOW, [NSNumber numberWithBool:show], OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)showActivityIndicatorView{
    return [objc_getAssociatedObject(self, &TAG_ACTIVITY_SHOW) boolValue];
}

// 设置UIActivityIndicatorView 的样式的属性，get & set 方法
- (void)setIndicatorStyle:(UIActivityIndicatorViewStyle)style{
    objc_setAssociatedObject(self, &TAG_ACTIVITY_STYLE, [NSNumber numberWithInt:style], OBJC_ASSOCIATION_RETAIN);
}

- (int)getIndicatorStyle{
    return [objc_getAssociatedObject(self, &TAG_ACTIVITY_STYLE) intValue];
}

// 在uiimageview 上添加 UIActivityIndicatorView
- (void)addActivityIndicator {
    if (!self.activityIndicator) {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[self getIndicatorStyle]];
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;

        // 菊花居中显示
        dispatch_main_async_safe(^{
            [self addSubview:self.activityIndicator];

            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.0
                                                              constant:0.0]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1.0
                                                              constant:0.0]];
        });
    }

    dispatch_main_async_safe(^{
        [self.activityIndicator startAnimating];
    });

}

// 在uiimageview 上移除 UIActivityIndicatorView
- (void)removeActivityIndicator {
    if (self.activityIndicator) {
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;
    }
}

@end


// 废弃的方法
@implementation UIImageView (WebCacheDeprecated)

- (NSURL *)imageURL {
    return [self sd_imageURL];
}

- (void)setImageWithURL:(NSURL *)url {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:progressBlock completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (completedBlock) {
            completedBlock(image, error, cacheType);
        }
    }];
}

- (void)sd_setImageWithPreviousCachedImageWithURL:(NSURL *)url andPlaceholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletionBlock)completedBlock {
    [self sd_setImageWithPreviousCachedImageWithURL:url placeholderImage:placeholder options:options progress:progressBlock completed:completedBlock];
}

- (void)cancelCurrentArrayLoad {
    [self sd_cancelCurrentAnimationImagesLoad];
}

- (void)cancelCurrentImageLoad {
    [self sd_cancelCurrentImageLoad];
}

- (void)setAnimationImagesWithURLs:(NSArray *)arrayOfURLs {
    [self sd_setAnimationImagesWithURLs:arrayOfURLs];
}

@end
