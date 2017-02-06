//
//  TWOneViewController.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWOneViewController.h"
#import "TWPresentAnimation.h"
#import "TWDismissAnimation.h"
#import "TWPanTransition.h"

@interface TWOneViewController ()<UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) TWPanTransition *panTransition;

@end

@implementation TWOneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn addTarget:self action:@selector(dismissBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    [btn setTitle:@"Dismiss" forState:UIControlStateNormal];
    [btn sizeToFit];
    btn.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    
    NSLog(@"btn.center = %@",NSStringFromCGPoint(btn.center));
    
    btn.backgroundColor = [UIColor orangeColor];
    

    self.view.backgroundColor = [UIColor lightGrayColor];
    
    
    self.transitioningDelegate = self;
//    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.modalPresentationStyle = UIModalPresentationCustom;
    
    self.panTransition = [[TWPanTransition alloc] init];
    [self.panTransition wireToViewController:self];
    
}

- (void)dismissBtnClicked:(UIButton*)sender{
    if(self.delegate && [self .delegate respondsToSelector:@selector(oneViewControllerDidClickedMissBtn:)]){
        [self.delegate oneViewControllerDidClickedMissBtn:sender];
    }
}
- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    NSLog(@"%s",__func__);
    return [[TWPresentAnimation alloc] init];
//    return nil;
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    NSLog(@"%s",__func__);
    return [[TWDismissAnimation alloc] init];
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator{
    NSLog(@"%s",__func__);
    return self.panTransition.interacting ? self.panTransition : nil;
//    return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
