//  代码地址: https://github.com/CoderMJLee/MJRefresh
//  代码地址: http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  MJRefreshHeader.m
//  MJRefreshExample
//
//  Created by MJ Lee on 15/3/4.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import "MJRefreshHeader.h"

@interface MJRefreshHeader()
@property (assign, nonatomic) CGFloat insetTDelta;
@end

@implementation MJRefreshHeader
#pragma mark - 构造方法
// 创建header
+ (instancetype)headerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock
{
    MJRefreshHeader *cmp = [[self alloc] init];
    cmp.refreshingBlock = refreshingBlock;
    return cmp;
}

// 创建header
+ (instancetype)headerWithRefreshingTarget:(id)target refreshingAction:(SEL)action
{
    MJRefreshHeader *cmp = [[self alloc] init];
    [cmp setRefreshingTarget:target refreshingAction:action];
    return cmp;
}

#pragma mark - 覆盖父类的方法
- (void)prepare
{
    [super prepare];
    
    // 设置key
    self.lastUpdatedTimeKey = MJRefreshHeaderLastUpdatedTimeKey;
    
    // 设置高度，设置header的高度
    self.mj_h = MJRefreshHeaderHeight;
}

- (void)placeSubviews
{
    [super placeSubviews];
    
    // 设置y值(当自己的高度发生改变了，肯定要重新调整Y值，所以放到placeSubviews方法中设置y值)
    // 设置y值，例如，-54
    self.mj_y = - self.mj_h - self.ignoredScrollViewContentInsetTop;
}

// scrollView的 ContentOffset 发生变化，监听scrollview的核心代码
- (void)scrollViewContentOffsetDidChange:(NSDictionary *)change
{
    // 调用super 的scrollViewContentOffsetDidChange
    [super scrollViewContentOffsetDidChange:change];
    
    // 在刷新的refreshing状态，这段代码暂时不理解作用，先跳过吧
    if (self.state == MJRefreshStateRefreshing) {
        if (self.window == nil) return;
        
        // sectionheader停留解决
        CGFloat insetT = - self.scrollView.mj_offsetY > _scrollViewOriginalInset.top ? - self.scrollView.mj_offsetY : _scrollViewOriginalInset.top;
        insetT = insetT > self.mj_h + _scrollViewOriginalInset.top ? self.mj_h + _scrollViewOriginalInset.top : insetT;
        self.scrollView.mj_insetT = insetT;
        
        self.insetTDelta = _scrollViewOriginalInset.top - insetT;
        return;
    }
    
    // 跳转到下一个控制器时，contentInset可能会变
     _scrollViewOriginalInset = self.scrollView.contentInset;
    
    // 当前的contentOffset
    CGFloat offsetY = self.scrollView.mj_offsetY;
    // 头部控件刚好出现的offsetY,就是往下拉的时候，下边刚好出现的offset。例如self.scrollViewOriginalInset.top为0，
    //  则scrolleview 的偏移为0，self.scrollViewOriginalInset.top为64，则offset为-64，就是头部控件平时状态，隐藏状态的offset，初始状态，不刷新的状态
    CGFloat happenOffsetY = - self.scrollViewOriginalInset.top;
    
    // 如果是向上滚动到看不见头部控件，直接返回
    // >= -> >
    // offset 为10,happenOffsetY 为0，则是向上滚动
    if (offsetY > happenOffsetY) return;
    
    // 普通 和 即将刷新 的临界点
    // header刚好整个显示在界面上，这个时候offset，假如happenOffsetY为0，则刚好全部显示的offset为 0-54，happenOffsetY为-64，则offset 为 - 64 - 54
    CGFloat normal2pullingOffsetY = happenOffsetY - self.mj_h;
    
    // 计算header被拉出的百分比，假如happenOffsetY为0，则偏移量就是offset,
    // pullingPercent 会超过1
    CGFloat pullingPercent = (happenOffsetY - offsetY) / self.mj_h;
    
//    NSLog(@"pullingPercent = %f",pullingPercent);
    
    if (self.scrollView.isDragging) { // 如果正在拖拽
        // 用户的手还没释放，还在拖拽中
        // 拉出的百分比
        self.pullingPercent = pullingPercent;
        
        if (self.state == MJRefreshStateIdle && offsetY < normal2pullingOffsetY) {
            // 转为即将刷新状态
            // 从头部完全没显示出来，并且是MJRefreshStateIdle的状态，整个header已经全部被拉出来，normal2pullingOffsetY = -54，offsetY < -54
            self.state = MJRefreshStatePulling;
            NSLog(@"变为松手即可刷新的状态 offsetY = %f",offsetY);
            NSLog(@"变为松手即可刷新的状态 normal2pullingOffsetY = %f",normal2pullingOffsetY);
            
        } else if (self.state == MJRefreshStatePulling && offsetY >= normal2pullingOffsetY) {
            // 转为普通状态
            // 在拖拽的时候，有MJRefreshStatePulling变为MJRefreshStateIdle
            self.state = MJRefreshStateIdle;
        }
    } else if (self.state == MJRefreshStatePulling) {// 即将刷新 && 手松开
        // 开始刷新
        // 整个header已经全部被拉出来，松手即可刷新的状态
        [self beginRefreshing];
    } else if (pullingPercent < 1) {
        self.pullingPercent = pullingPercent;
    }
}

// 设置header的状态
- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState
    
    // 根据状态做事情
    // 由刷新中变为普通状态，即调用了，endRefreshing
    if (state == MJRefreshStateIdle) {
        if (oldState != MJRefreshStateRefreshing) return;
        
        // 保存刷新时间
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:self.lastUpdatedTimeKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // 恢复inset和offset，由刷新中变为普通状态，即调用了，endRefreshing
        [UIView animateWithDuration:MJRefreshSlowAnimationDuration animations:^{
            self.scrollView.mj_insetT += self.insetTDelta;
            
            // 自动调整透明度
            if (self.isAutomaticallyChangeAlpha) self.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.pullingPercent = 0.0;
            
            // 结束刷新的通知
            if (self.endRefreshingCompletionBlock) {
                self.endRefreshingCompletionBlock();
            }
        }];
    } else if (state == MJRefreshStateRefreshing) {
        // 进入刷新状态
         dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:MJRefreshFastAnimationDuration animations:^{
                // scrollViewOriginalInset.top 为0，mj_h 为54，则top = 54；
                CGFloat top = self.scrollViewOriginalInset.top + self.mj_h;
                // 增加滚动区域top
                // 设置inset，让header不回弹
                self.scrollView.mj_insetT = top;
                // 设置滚动位置
                // 回弹到-54的位置，header刚好整个显示出来的位置
                [self.scrollView setContentOffset:CGPointMake(0, -top) animated:NO];
            } completion:^(BOOL finished) {
                [self executeRefreshingCallback];
            }];
         });
    }
}

#pragma mark - 公共方法
// 结束刷新
- (void)endRefreshing
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.state = MJRefreshStateIdle;
    });
}

- (NSDate *)lastUpdatedTime
{
    // 存储指定key 的时间
    return [[NSUserDefaults standardUserDefaults] objectForKey:self.lastUpdatedTimeKey];
}
@end
