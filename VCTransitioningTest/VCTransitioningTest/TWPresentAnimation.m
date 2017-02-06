//
//  TWPresentAnimation.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWPresentAnimation.h"

@implementation TWPresentAnimation


- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext{
    return 0.5;
}
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext{
    NSLog(@"%s",__func__);
    [self tets1:transitionContext];
    
//    [self tets2:transitionContext];
}

- (void)tets2:(id <UIViewControllerContextTransitioning>)transitionContext{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *fromVCView = [fromVC.view snapshotViewAfterScreenUpdates:NO];
    
    fromVCView.tag = 100;
    
    fromVC.view.hidden = YES;
    
    fromVCView.bounds = fromVC.view.bounds;
    
    CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];
    
    finalFrame.size.height = 400;
    finalFrame.origin.y = [UIScreen mainScreen].bounds.size.height  - finalFrame.size.height;
    
    toVC.view.frame = CGRectOffset(finalFrame, 0, finalFrame.size.height);
    
    UIView *containerView = [transitionContext containerView];
    
    [containerView addSubview:fromVCView];
    
    [containerView addSubview:toVC.view];
    
    CGFloat duration = [self transitionDuration:transitionContext];
    
    
    [UIView animateWithDuration:duration
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:1.0 / 0.55
                        options:0
                     animations:^{
                         toVC.view.transform = CGAffineTransformMakeTranslation(0, -400);
                         fromVCView.transform = CGAffineTransformMakeScale(0.85, 0.85);
                     }
                     completion:^(BOOL finished) {
                         [transitionContext completeTransition:YES];
                     }];
    
//    [UIView animateWithDuration:duration
//                     animations:^{
////                         toVC.view.frame = finalFrame;
//                         toVC.view.transform = CGAffineTransformMakeTranslation(0, -400);
//                         fromVCView.transform = CGAffineTransformMakeScale(0.8, 0.8);
//                     }
//                     completion:^(BOOL finished) {
//                         [transitionContext completeTransition:YES];
//                     }];
    
}

- (void)tets1:(id <UIViewControllerContextTransitioning>)transitionContext{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    
    CGRect finalFrame = [transitionContext finalFrameForViewController:toVC];
    toVC.view.frame = CGRectOffset(finalFrame, 0, finalFrame.size.height);
    
    UIView *containerView = [transitionContext containerView];
    
    [containerView addSubview:toVC.view];
    
    CGFloat duration = [self transitionDuration:transitionContext];
    
    
    [UIView animateWithDuration:duration
                     animations:^{
                         toVC.view.frame = finalFrame;
                     }
                     completion:^(BOOL finished) {
                         [transitionContext completeTransition:YES];
                     }];
    
}

@end
