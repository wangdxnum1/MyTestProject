//
//  MJRefreshBackFooter.m
//  MJRefreshExample
//
//  Created by MJ Lee on 15/4/24.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import "MJRefreshBackFooter.h"

@interface MJRefreshBackFooter()
@property (assign, nonatomic) NSInteger lastRefreshCount;
@property (assign, nonatomic) CGFloat lastBottomDelta;
@end

@implementation MJRefreshBackFooter

#pragma mark - 初始化
- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    // 这句代码赞不理解用途,是为了设置footer的位置
    [self scrollViewContentSizeDidChange:nil];
}

#pragma mark - 实现父类的方法
// scrollview 的 ContentOffset 发生改变
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change
{
    // 调用父类的
    [super scrollViewContentOffsetDidChange:change];
    
    // 如果正在刷新，直接返回，是刷新的状态，直接返回
    if (self.state == MJRefreshStateRefreshing) return;
    
    _scrollViewOriginalInset = self.scrollView.contentInset;
    
    // 当前的contentOffset
    CGFloat currentOffsetY = self.scrollView.mj_offsetY;
    
    // 尾部控件刚好出现的offsetY
    CGFloat happenOffsetY = [self happenOffsetY];
    
    NSLog(@"happenOffsetY = %f",happenOffsetY);
    
    // 如果是向下滚动到看不见尾部控件，直接返回,底部控件看不到了
    if (currentOffsetY <= happenOffsetY) return;
    
    // 底部控件拉出的百分比，currentOffsetY 比 happenOffsetY大
    CGFloat pullingPercent = (currentOffsetY - happenOffsetY) / self.mj_h;
    
    // 如果已全部加载，仅设置pullingPercent，然后返回
    if (self.state == MJRefreshStateNoMoreData) {
        // 是没有更多数据的状态，不做其他事情
        self.pullingPercent = pullingPercent;
        return;
    }
    
    // 用户还未松手，还在拖拽中
    if (self.scrollView.isDragging) {
        self.pullingPercent = pullingPercent;
        // 普通 和 即将刷新 的临界点
        // 整个footer已经刚好整个显示出来
        CGFloat normal2pullingOffsetY = happenOffsetY + self.mj_h;
        
        if (self.state == MJRefreshStateIdle && currentOffsetY > normal2pullingOffsetY) {
            // 转为即将刷新状态
            // 已经大于normal2pullingOffsetY，这松手可以刷新
            self.state = MJRefreshStatePulling;
        } else if (self.state == MJRefreshStatePulling && currentOffsetY <= normal2pullingOffsetY) {
            // 转为普通状态
            // pulling 的状态下，又往下拽，变为MJRefreshStateIdle
            self.state = MJRefreshStateIdle;
        }
    } else if (self.state == MJRefreshStatePulling) {// 即将刷新 && 手松开
        // 开始刷新
        // 已经松手，变为刷新状态，开始刷新
        [self beginRefreshing];
    } else if (pullingPercent < 1) {
        self.pullingPercent = pullingPercent;
    }
}

- (void)scrollViewContentSizeDidChange:(NSDictionary *)change
{
    [super scrollViewContentSizeDidChange:change];
    
    // 内容的高度
    CGFloat contentHeight = self.scrollView.mj_contentH + self.ignoredScrollViewContentInsetBottom;
    // 表格的高度
    CGFloat scrollHeight = self.scrollView.mj_h - self.scrollViewOriginalInset.top - self.scrollViewOriginalInset.bottom + self.ignoredScrollViewContentInsetBottom;
    // 设置位置和尺寸
    
    self.mj_y = MAX(contentHeight, scrollHeight);
    
    NSLog(@"%f",self.mj_y);
}

- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState
    
    // 根据状态来设置属性
    if (state == MJRefreshStateNoMoreData || state == MJRefreshStateIdle) {
        // 刷新完毕
        if (MJRefreshStateRefreshing == oldState) {
            [UIView animateWithDuration:MJRefreshSlowAnimationDuration animations:^{
                self.scrollView.mj_insetB -= self.lastBottomDelta;
                
                // 自动调整透明度
                if (self.isAutomaticallyChangeAlpha) self.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.pullingPercent = 0.0;
                
                if (self.endRefreshingCompletionBlock) {
                    self.endRefreshingCompletionBlock();
                }
            }];
        }
        
        CGFloat deltaH = [self heightForContentBreakView];
        // 刚刷新完毕
        if (MJRefreshStateRefreshing == oldState && deltaH > 0 && self.scrollView.mj_totalDataCount != self.lastRefreshCount) {
            self.scrollView.mj_offsetY = self.scrollView.mj_offsetY;
        }
    } else if (state == MJRefreshStateRefreshing) {
        // 记录刷新前的数量
        self.lastRefreshCount = self.scrollView.mj_totalDataCount;
        
        [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
            CGFloat bottom = self.mj_h + self.scrollViewOriginalInset.bottom;
            CGFloat deltaH = [self heightForContentBreakView];
            if (deltaH < 0) { // 如果内容高度小于view的高度
                bottom -= deltaH;
            }
            self.lastBottomDelta = bottom - self.scrollView.mj_insetB;
            self.scrollView.mj_insetB = bottom;
            self.scrollView.mj_offsetY = [self happenOffsetY] + self.mj_h;
        } completion:^(BOOL finished) {
            [self executeRefreshingCallback];
        }];
    }
}

- (void)endRefreshing
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.state = MJRefreshStateIdle;
    });
}

- (void)endRefreshingWithNoMoreData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.state = MJRefreshStateNoMoreData;
    });
}
#pragma mark - 私有方法
#pragma mark 获得scrollView的内容 超出 view 的高度
- (CGFloat)heightForContentBreakView
{
    // 假设bottom 为0，top为64，scrollView为568，即可见区域，滚动区域568 - 64 = 502
    CGFloat h = self.scrollView.frame.size.height - self.scrollViewOriginalInset.bottom - self.scrollViewOriginalInset.top;
    // 假设contentSize 也为568，则还有64部分在尾部，需要上拉显示
    return self.scrollView.contentSize.height - h;
}

#pragma mark 刚好看到上拉刷新控件时的contentOffset.y
- (CGFloat)happenOffsetY
{
    CGFloat deltaH = [self heightForContentBreakView];
    if (deltaH > 0) {
        // 上拉64，是整个内容最后刚好显示在底部，这个时候的contentoffset为0
        return deltaH - self.scrollViewOriginalInset.top;
    } else {
        return - self.scrollViewOriginalInset.top;
    }
}
@end
