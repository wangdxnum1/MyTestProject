//
//  TWPopAnimation.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWPopAnimation.h"
#import "TWTwoViewController.h"
#import "TWThreeViewController.h"
#import "XWMagicMoveCell.h"


@implementation TWPopAnimation

- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext{
    return 0.75;
}
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext{
    NSLog(@"%s",__func__);
    
    TWThreeViewController*fromVC = (TWThreeViewController*)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    TWTwoViewController *toVC = (TWTwoViewController*)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    XWMagicMoveCell *cell = (XWMagicMoveCell*)[toVC.collectionView cellForItemAtIndexPath:toVC.currentIndexPath];
    
//    UIView *tempView = [fromVC.imageView snapshotViewAfterScreenUpdates:NO];
//    tempView.bounds = fromVC.imageView.bounds;
//    tempView.frame = [fromVC.imageView convertRect:fromVC.imageView.frame toView:containerView];
    UIView *containerView = [transitionContext containerView];
    
    UIView *tempView = containerView.subviews.lastObject;
    
    tempView.hidden = NO;
    
    [containerView insertSubview:toVC.view atIndex:0];
    [containerView addSubview:tempView];
    
    fromVC.imageView.hidden = YES;
    cell.imageView.hidden = YES;
    fromVC.view.alpha = 1;
    
    CGFloat duration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:duration
                          delay:0
         usingSpringWithDamping:0.55
          initialSpringVelocity:1/0.55
                        options:0
                     animations:^{
                         tempView.frame = [cell.imageView convertRect:cell.imageView.bounds toView:containerView];
                         fromVC.view.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         cell.imageView.hidden = NO;
                         tempView.hidden = YES;
                         [transitionContext completeTransition:YES];
                     }];

}

@end
