//
//  TWThreeViewController.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWThreeViewController.h"
#import "TWPresentAnimation.h"
#import "TWDismissAnimation.h"
#import "TWPushAnimation.h"
#import "TWPopAnimation.h"

@implementation TWThreeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.title = @"push detai";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC{
    
    NSLog(@"%@", NSStringFromCGRect(self.imageView.frame));
    if(operation == UINavigationControllerOperationPush){
//        return [[TWPresentAnimation alloc] init];
        return [[TWPushAnimation alloc] init];
    }else{
//        return [[TWDismissAnimation alloc] init];
        return [[TWPopAnimation alloc] init];
    }
//    return nil;
}
- (void)dealloc{
    NSLog(@"TWThreeViewController 销毁了");
}

@end
