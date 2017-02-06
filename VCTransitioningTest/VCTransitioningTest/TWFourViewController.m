//
//  TWFourViewController.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWFourViewController.h"

@interface TWFourViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation TWFourViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.imageView.layer.anchorPoint = CGPointMake(0, 0.5);
    self.imageView.layer.position = CGPointMake(0,self.view.frame.size.height/2);
    self.imageView.center = CGPointMake(0,self.view.frame.size.height/2);
    
    
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 0.002;
    
    self.imageView.layer.transform = transform;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    
    
    [UIView animateWithDuration:0.75
                     animations:^{
                         self.imageView.layer.transform = CATransform3DMakeRotation(-M_PI_2, 0, 1, 0);
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

@end
