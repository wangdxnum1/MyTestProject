//
//  ViewController.m
//  SDWebImageTest
//
//  Created by HaKim on 16/7/5.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+WebCache.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    NSURL *url = [NSURL URLWithString:@"http://e.hiphotos.baidu.com/image/h%3D200/sign=5a188e1c2f381f3081198aa999014c67/242dd42a2834349bc70cd2a1ceea15ce36d3be88.jpg"];
    [self.imageView setShowActivityIndicatorView:YES];
    [self.imageView setIndicatorStyle:UIActivityIndicatorViewStyleGray];
    //    [self.imageView sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    //
    //    }];
    [self.imageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageProgressiveDownload | SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        NSLog(@"imageView cacheType = %zd",cacheType);
    }];
    
    [self.imageView2 sd_setImageWithURL:url placeholderImage:nil options:SDWebImageProgressiveDownload | SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        NSLog(@"imageView2 cacheType = %zd",cacheType);
    }];
    
    SDImageCache *cache = [SDImageCache sharedImageCache];
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    NSString *key = [manager cacheKeyForURL:url];
    
    NSString *path = [cache defaultCachePathForKey:key];
    
    NSLog(@"path = %@",path);
    
    double money = 5.89;
    NSInteger moneyiii = (int)money;
    NSLog(@"nmoney = %ld",moneyiii);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}

@end
