//
//  TWTestViewController.m
//  TWMyScrollView
//
//  Created by HaKim on 2017/4/28.
//  Copyright © 2017年 haKim. All rights reserved.
//

#import "TWTestViewController.h"

@interface TWTestViewController ()

@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic, weak) CAShapeLayer *shapeLayer;

@end

@implementation TWTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self commonInit];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)valueChanged:(UISlider*)slider{
    NSLog(@"slider = %@",@(slider.value));
    
    self.shapeLayer.strokeEnd = slider.value;
}

- (void)commonInit{
    [self.slider addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.bounds = CGRectMake(0, 0, 24, 24);
//    #EE4F52
    shapeLayer.strokeColor = [UIColor colorWithRed:0xee/255.0 green:0x4f/255.0 blue:0x52/255.0 alpha:1].CGColor;
    shapeLayer.lineWidth = 1.5;
    
    shapeLayer.strokeStart = 0;
    shapeLayer.strokeEnd = 0;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    
    self.shapeLayer = shapeLayer;
    
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(12, 12) radius:12 startAngle:0 endAngle:2 *M_PI clockwise:YES];
    
    shapeLayer.path = path.CGPath;
    
    [self.contentView.layer addSublayer:shapeLayer];
}

@end
