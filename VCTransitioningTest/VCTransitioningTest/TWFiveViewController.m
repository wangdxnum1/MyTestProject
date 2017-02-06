//
//  TWFiveViewController.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWFiveViewController.h"

@interface TWFiveViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;


@property (nonatomic, assign) CGRect startFrame;

@end


@implementation TWFiveViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.startFrame = CGRectMake(0, 0, 20, 20);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint centerPoint  = [touch locationInView:self.view];
    
    CGFloat x = centerPoint.x - self.startFrame.size.width / 2;
    CGFloat y = centerPoint.y - self.startFrame.size.height / 2;
    
    CGRect frame = CGRectMake(x, y, self.startFrame.size.width, self.startFrame.size.height);
    
    self.startFrame = frame;
    
    NSLog(@" self.startFrame = %@",NSStringFromCGRect( self.startFrame));
    
    UIBezierPath *startCycle =  [UIBezierPath bezierPathWithOvalInRect:self.startFrame];
    
    x = MAX(self.startFrame.origin.x, self.view.frame.size.width - self.startFrame.origin.x);
    
    y = MAX(self.startFrame.origin.y, self.view.frame.size.height - self.startFrame.origin.y);
    
    CGFloat radius = sqrtf(pow(x, 2) + pow(y, 2));
    
    UIBezierPath *endCycle = [UIBezierPath bezierPathWithArcCenter:self.view.center radius:radius startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    
    //创建CAShapeLayer进行遮盖
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = endCycle.CGPath;
    
    //将maskLayer作为toVC.View的遮盖
    self.imageView.layer.mask = maskLayer;
    
    //创建路径动画
    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskLayerAnimation.delegate = self;
    
    //动画是加到layer上的，所以必须为CGPath，再将CGPath桥接为OC对象
    maskLayerAnimation.fromValue = (__bridge id)(startCycle.CGPath);
    maskLayerAnimation.toValue = (__bridge id)((endCycle.CGPath));
    maskLayerAnimation.duration = 0.75;
    maskLayerAnimation.delegate = self;
    maskLayerAnimation.timingFunction = [CAMediaTimingFunction  functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    [maskLayer addAnimation:maskLayerAnimation forKey:@"path"];
}

@end
