//
//  MJRefreshNormalHeader.m
//  MJRefreshExample
//
//  Created by MJ Lee on 15/4/24.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import "MJRefreshNormalHeader.h"
#import "NSBundle+MJRefresh.h"

@interface MJRefreshNormalHeader()
{
    // 箭头的图片
    __unsafe_unretained UIImageView *_arrowView;
}

// 菊花
@property (weak, nonatomic) UIActivityIndicatorView *loadingView;

@end

@implementation MJRefreshNormalHeader

#pragma mark - 懒加载子控件
- (UIImageView *)arrowView
{
    if (!_arrowView) {
        UIImageView *arrowView = [[UIImageView alloc] initWithImage:[NSBundle mj_arrowImage]];
        [self addSubview:_arrowView = arrowView];
    }
    return _arrowView;
}

- (UIActivityIndicatorView *)loadingView
{
    if (!_loadingView) {
        UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.activityIndicatorViewStyle];
        loadingView.hidesWhenStopped = YES;
        [self addSubview:_loadingView = loadingView];
    }
    return _loadingView;
}

#pragma mark - 公共方法
- (void)setActivityIndicatorViewStyle:(UIActivityIndicatorViewStyle)activityIndicatorViewStyle
{
    _activityIndicatorViewStyle = activityIndicatorViewStyle;
    
    self.loadingView = nil;
    [self setNeedsLayout];
}

#pragma mark - 重写父类的方法
- (void)prepare
{
    [super prepare];
    
    self.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
}

- (void)placeSubviews
{
    [super placeSubviews];
    
    // 箭头的中心点
    CGFloat arrowCenterX = self.mj_w * 0.5;
    // 有状态的label时候
    if (!self.stateLabel.hidden) {
        // 获取文字的宽度
        CGFloat stateWidth = self.stateLabel.mj_textWith;
        CGFloat timeWidth = 0.0;
        // 有时间拉不了的时候
        if (!self.lastUpdatedTimeLabel.hidden) {
            // 获取显示的时间的宽度
            timeWidth = self.lastUpdatedTimeLabel.mj_textWith;
        }
        // 获取两个最大的宽度
        CGFloat textWidth = MAX(stateWidth, timeWidth);
        
        arrowCenterX -= textWidth / 2 + self.labelLeftInset;
    }
    CGFloat arrowCenterY = self.mj_h * 0.5;
    // 箭头的中心位置
    CGPoint arrowCenter = CGPointMake(arrowCenterX, arrowCenterY);
    
    // 箭头
    if (self.arrowView.constraints.count == 0) {
        self.arrowView.mj_size = self.arrowView.image.size;
        self.arrowView.center = arrowCenter;
    }
        
    // 圈圈
    if (self.loadingView.constraints.count == 0) {
        self.loadingView.center = arrowCenter;
    }
    
    // 不设置箭头颜色是蓝色的。。。
    self.arrowView.tintColor = self.stateLabel.textColor;
//    self.arrowView.tintColor = [UIColor redColor];
//    self.arrowView.image = [self.arrowView.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (void)setState:(MJRefreshState)state
{
    // 检查旧的状态与要设置的状态，一样的话，直接返回，然后先调用父类的方法
    MJRefreshCheckState
    
    // 根据状态做事情
    if (state == MJRefreshStateIdle) {
        // 从刷新中变为普通状态
        if (oldState == MJRefreshStateRefreshing) {
            
            // 刷新中变为普通状态，例如调用endRefreshing,结束刷新状态,箭头变为向下的状态
            self.arrowView.transform = CGAffineTransformIdentity;
            
            [UIView animateWithDuration:MJRefreshSlowAnimationDuration animations:^{
                self.loadingView.alpha = 0.0;
            } completion:^(BOOL finished) {
                // 如果执行完动画发现不是idle状态，就直接返回，进入其他状态
                if (self.state != MJRefreshStateIdle) return;
                
                // 设置为普通状态
                self.loadingView.alpha = 1.0;
                [self.loadingView stopAnimating];
                self.arrowView.hidden = NO;
            }];
        } else {
            // 从其他状态变为普通状态，也是设置为普通状态，结束刷新
            [self.loadingView stopAnimating];
            self.arrowView.hidden = NO;
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                self.arrowView.transform = CGAffineTransformIdentity;
            }];
        }
    } else if (state == MJRefreshStatePulling) {
        // 变为松手可以刷新的状态
        [self.loadingView stopAnimating];
        self.arrowView.hidden = NO;
        // 箭头向上
        [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
            self.arrowView.transform = CGAffineTransformMakeRotation(0.000001 - M_PI);
        }];
    } else if (state == MJRefreshStateRefreshing) {
        // 进入刷新状态
        self.loadingView.alpha = 1.0; // 防止refreshing -> idle的动画完毕动作没有被执行
        [self.loadingView startAnimating];
        self.arrowView.hidden = YES;
    }
}

@end
