//
//  TWPushAnimation.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWPushAnimation.h"
#import "TWTwoViewController.h"
#import "TWThreeViewController.h"
#import "XWMagicMoveCell.h"


@implementation TWPushAnimation

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext{
    return 0.75;
}


- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext{
    NSLog(@"%s",__func__);
    TWTwoViewController *fromVC = (TWTwoViewController*)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    TWThreeViewController *toVC = (TWThreeViewController*)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    
    XWMagicMoveCell *cell = (XWMagicMoveCell*)[fromVC.collectionView cellForItemAtIndexPath:fromVC.currentIndexPath];
    
    UIImageView *imageView = cell.imageView;
    
    UIView *tempView = [imageView snapshotViewAfterScreenUpdates:NO];
    tempView.bounds = imageView.bounds;
    
    UIView *containerView = [transitionContext containerView];
    
    tempView.frame =  [imageView convertRect:imageView.frame toView:containerView];
    NSLog(@"tempView.frame = %@",NSStringFromCGRect(tempView.frame));
    
    [containerView addSubview:toVC.view];
    [containerView addSubview:tempView];
    
    
    imageView.hidden = YES;
    toVC.imageView.hidden = YES;
    toVC.view.alpha = 0;
    
    CGFloat duration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:duration
                          delay:0
         usingSpringWithDamping:0.55
          initialSpringVelocity:1/0.55
                        options:0
                     animations:^{
                         tempView.frame = [toVC.imageView convertRect:toVC.imageView.bounds toView:containerView];
                         toVC.view.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         imageView.hidden = NO;
                         tempView.hidden = YES;
                         toVC.imageView.hidden = NO;
                         [transitionContext completeTransition:YES];
                     }];
    
}


@end
