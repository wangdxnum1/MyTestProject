//
//  TWZhiRefreshHeader.m
//  TWMyScrollView
//
//  Created by HaKim on 2017/4/28.
//  Copyright © 2017年 haKim. All rights reserved.
//

#import "TWZhiRefreshHeader.h"


CGRect kZZZLogoViewBounds = {0,0,24,24};

@interface TWZhiRefreshHeader ()

@property (nonatomic, strong) UIImageView *circleView;

@property (nonatomic, strong) UIImageView *logoView;

@property (nonatomic, strong) CAShapeLayer *circleLayer;

@property (nonatomic, assign) BOOL hasRefreshed;

@end

@implementation TWZhiRefreshHeader

#pragma mark 在这里做一些初始化配置（比如添加子控件）
- (void)prepare
{
    [super prepare];
    [self.logoView addSubview:self.circleView];
    [self.logoView.layer addSublayer:self.circleLayer];
    
    [self addSubview:self.logoView];
    
    self.hasRefreshed = NO;//初始化的时候，肯定是没有刷新过的
}
#pragma mark 监听控件的刷新状态
- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState;
    
    switch (state) {
        case MJRefreshStateIdle:
            self.circleView.hidden = YES;
            self.circleLayer.hidden = NO;
            break;
        case MJRefreshStatePulling:
            break;
        case MJRefreshStateRefreshing:
            self.circleView.hidden = NO;
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            self.circleLayer.hidden = YES;
            [CATransaction commit];
            
            self.hasRefreshed = YES;//刷新过了
            
            [self.circleView.layer addAnimation:[self creatTransformAnimation] forKey:nil];
            break;
        default:
            break;
    }
}

- (void)setPullingPercent:(CGFloat)pullingPercent
{
    [super setPullingPercent:pullingPercent];
    
    if (self.hasRefreshed) {//刷新返回的时候，strokeEnd = 1.0
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.circleLayer.strokeEnd = 1.0;
        [CATransaction commit];
        self.hasRefreshed = NO;//重置状态为未刷新
    }else{
        self.circleLayer.strokeEnd = pullingPercent;
    }
}

- (void)endRefreshing{
    [super endRefreshing];
    
    [self.circleView.layer removeAllAnimations];
}

- (CABasicAnimation*)creatTransformAnimation{
    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    a.toValue = @(2 * M_PI);
    a.duration = 2;
    a.repeatCount = MAXFLOAT;
    a.fillMode = kCAFillModeForwards;
    
    return a;
}

#pragma mark 在这里设置子控件的位置和尺寸

- (void)placeSubviews
{
    [super placeSubviews];
    self.logoView.center = CGPointMake(self.mj_w/2.0, self.mj_h/2.0 + 10.0);// +10是为了logoView在中心点往下一点的位置，方便观看
    self.logoView.bounds = kZZZLogoViewBounds;
    self.circleView.frame = self.logoView.bounds;
}

- (UIImageView *)logoView{
    if (!_logoView) {
        _logoView = [[UIImageView alloc] init];
        _logoView.image = [UIImage imageNamed:@"zhi"];
    }
    return _logoView;
}

- (UIImageView *)circleView{
    if (!_circleView) {
        _circleView = [[UIImageView alloc] init];
        _circleView.image = [UIImage imageNamed:@"circle"];
        _circleView.hidden = YES; //刷新时候的图片，开始的时候不需要显示出来
    }
    return _circleView;
}

- (CAShapeLayer *)circleLayer{
    if (!_circleLayer) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.frame = CGRectMake(0, 0, 24, 24);

        shapeLayer.strokeColor = [UIColor colorWithRed:0xee/255.0 green:0x4f/255.0 blue:0x52/255.0 alpha:1].CGColor;
        shapeLayer.lineWidth = 1.5;
        
        shapeLayer.strokeStart = 0;
        shapeLayer.strokeEnd = 0;
        shapeLayer.fillColor = [UIColor clearColor].CGColor;
        
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(12, 12) radius:12 startAngle:0 endAngle:2 *M_PI clockwise:YES];
        
        shapeLayer.path = path.CGPath;
        
        _circleLayer = shapeLayer;

    }
    return _circleLayer;
}

@end
