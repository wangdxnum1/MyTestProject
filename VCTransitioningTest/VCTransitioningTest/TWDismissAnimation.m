//
//  TWDismissAnimation.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWDismissAnimation.h"

@implementation TWDismissAnimation

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext{
    return 1.0;
}
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext{
    [self tets1:transitionContext];
//    [self tets2:transitionContext];
}

- (void)tets1:(id <UIViewControllerContextTransitioning>)transitionContext{
    NSLog(@"%s",__func__);
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = [transitionContext containerView];
    [containerView addSubview:toVC.view];
    [containerView sendSubviewToBack:toVC.view];
    
    CGRect initFrame = [transitionContext initialFrameForViewController:fromVC];
    
    CGRect finalFrame = CGRectOffset(initFrame, 0, initFrame.size.height);
    
    CGFloat duration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         fromVC.view.frame = finalFrame;
                     }
                     completion:^(BOOL finished) {
                         [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                     }];
}

- (void)tets2:(id <UIViewControllerContextTransitioning>)transitionContext{
    NSLog(@"%s",__func__);
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect finalFrame = [transitionContext finalFrameForViewController:fromVC];
    
    NSLog(@"finalFrame = %@",NSStringFromCGRect(finalFrame));
    
    
    CGFloat duration = [self transitionDuration:transitionContext];
    
    UIView *containerView = [transitionContext containerView];
    UIView *tmpView = [containerView viewWithTag:100];
    
    
    
    [UIView animateWithDuration:duration
                     animations:^{
                         fromVC.view.transform = CGAffineTransformIdentity;
                         
                         tmpView.transform = CGAffineTransformIdentity;
                     }
                     completion:^(BOOL finished) {
                         [transitionContext completeTransition:YES];
                         [containerView willRemoveSubview:tmpView];
                         toVC.view.hidden = NO;
                     }];
}

@end
