//
//  TWTestView.m
//  TWMyScrollView
//
//  Created by HaKim on 2017/4/28.
//  Copyright © 2017年 haKim. All rights reserved.
//

#import "TWTestView.h"

@interface TWTestView ()

@property (nonatomic, strong) UIImageView *circleView;

@property (nonatomic, strong) UIImageView *logoView;

@end

@implementation TWTestView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews{
    self.logoView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    self.logoView.bounds = CGRectMake(0, 0, 24, 24);
    self.circleView.frame = self.logoView.bounds;
    
    
    CABasicAnimation *a = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    a.toValue = @(2 * M_PI);
    a.duration = 2;
    a.repeatCount = MAXFLOAT;
    a.fillMode = kCAFillModeForwards;
    
    [self.circleView.layer addAnimation:a forKey:@"a.rototion"];
}

- (void)commonInit{
    [self.logoView addSubview:self.circleView];
    [self addSubview:self.logoView];
    

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
    }
    return _circleView;
}

@end
