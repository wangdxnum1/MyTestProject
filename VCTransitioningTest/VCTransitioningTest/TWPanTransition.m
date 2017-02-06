//
//  TWPanTransition.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWPanTransition.h"

@interface TWPanTransition ()

@property (nonatomic, assign) BOOL shouldComplete;

@property (nonatomic, strong) UIViewController *presentingVC;

@end

@implementation TWPanTransition

- (void)wireToViewController:(UIViewController *)viewController{
    self.presentingVC = viewController;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.presentingVC.view addGestureRecognizer:pan];
}

-(CGFloat)completionSpeed
{
    return 1 - self.percentComplete;
}

- (void)handlePan:(UIPanGestureRecognizer*)sender{
    CGPoint translatePoint = [sender translationInView:self.presentingVC.view];
    
    NSLog(@"translatePoint = %@",NSStringFromCGPoint(translatePoint));
    
    
    UIGestureRecognizerState state = sender.state;
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            self.interacting = YES;
            [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            
            if(translatePoint.y >= 0){
                CGFloat rate = translatePoint.y / 400.0;
                rate = MIN(rate, 1.0);
                
                self.shouldComplete = (rate >= 0.5);
                
                [self updateInteractiveTransition:rate];
            }
            
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            self.interacting = NO;
            if(self.shouldComplete){
                [self finishInteractiveTransition];
            }else{
                [self cancelInteractiveTransition];
            }
            break;
        }
            default:
            break;
    }
    
//    [self finishInteractiveTransition];
}

@end
