//
//  ViewController.m
//  PresentVCTest
//
//  Created by HaKim on 16/8/10.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "ModalViewController.h"
#import "BouncePresentAnimation.h"
#import "NormalDismissAnimation.h"

@interface ViewController ()<ModalViewControllerDelegate,UIViewControllerTransitioningDelegate>

@property (nonatomic, strong) BouncePresentAnimation *presentAnimation;

@property (nonatomic, strong) NormalDismissAnimation *dismissAnimation;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    [button setTitle:@"Click me" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    _presentAnimation = [BouncePresentAnimation new];
    _dismissAnimation = [NormalDismissAnimation new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) buttonClicked:(id)sender
{
    ModalViewController *mvc =  [[ModalViewController alloc] init];
    mvc.transitioningDelegate = self;
    mvc.delegate = self;
    [self presentViewController:mvc animated:YES completion:nil];
}

-(void)modalViewControllerDidClickedDismissButton:(ModalViewController *)viewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self.presentAnimation;
//    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return self.dismissAnimation;
    //    return nil;

}

@end
