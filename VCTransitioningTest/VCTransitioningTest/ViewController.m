//
//  ViewController.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "TWOneViewController.h"
#import "TWTwoViewController.h"
#import "TWFourViewController.h"
#import "TWFiveViewController.h"

@interface ViewController ()<TWOneViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    CAGradientLayer *toGradient = [CAGradientLayer layer];
//    toGradient.frame = self.view.bounds;
//    toGradient.colors = @[(id)[UIColor blackColor].CGColor,
//                          (id)[UIColor blackColor].CGColor];
//    toGradient.startPoint = CGPointMake(0.0, 0.5);
//    toGradient.endPoint = CGPointMake(0.8, 0.5);
//    
//    UIView *toShadow = [[UIView alloc]initWithFrame:self.view.bounds];
//    toShadow.backgroundColor = [UIColor clearColor];
//    [toShadow.layer insertSublayer:toGradient atIndex:1];
//    toShadow.alpha = 0.7;
//    [self.view addSubview:toShadow];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)clickmeBtnClicked:(UIButton *)sender {
    TWOneViewController *vc = [[TWOneViewController alloc] init];
    
    vc.delegate = self;
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)pageBtnClicked:(UIButton *)sender {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([TWFourViewController class])];
    
    [self.navigationController pushViewController:vc animated:YES];
}
- (IBAction)cirlceBtnClicked:(UIButton *)sender {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([TWFiveViewController class])];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)pushBtnClicked:(UIButton *)sender {
//    TWTwoViewController *vc = [[TWTwoViewController alloc] init];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([TWTwoViewController class])];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)oneViewControllerDidClickedMissBtn:(UIButton*)btn{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
