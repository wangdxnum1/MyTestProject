//
//  VTMagicController.m
//  VTMagicView
//
//  Created by tianzhuo on 14-11-11.
//  Copyright (c) 2014年 tianzhuo. All rights reserved.
//

#import "VTMagicController.h"

@interface VTMagicController ()


@end

@implementation VTMagicController

#pragma mark - Lifecycle
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    //  从xib中加载的初始化
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        } else if ([self respondsToSelector:@selector(setWantsFullScreenLayout:)]) {
            [self setValue:@YES forKey:@"wantsFullScreenLayout"];
        }
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    // 重写loadView，设置self.view为magicView
    self.view = self.magicView;
}

// 重写几个view 出现消失的函数
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _appearanceState = VTAppearanceStateWillAppear;
    if (!_magicView.isSwitching) {
        [_currentViewController beginAppearanceTransition:YES animated:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _appearanceState = VTAppearanceStateDidAppear;
    if (!_magicView.isSwitching) {
        [_currentViewController endAppearanceTransition];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _appearanceState = VTAppearanceStateWillDisappear;
    if (!_magicView.isSwitching) {
        [_currentViewController beginAppearanceTransition:NO animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    _appearanceState = VTAppearanceStateDidDisappear;
    if (!_magicView.isSwitching) {
        [_currentViewController endAppearanceTransition];
    }
}

#pragma mark - 禁止自动触发appearance methods

// 暂时不知道重写这个方法的作用
- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

#pragma mark - functional methods

// 获取对应pageIndex所在额的控制器
- (UIViewController *)viewControllerAtPage:(NSUInteger)pageIndex {
    // 内部调用magicView的方法获取
    return [self.magicView viewControllerAtPage:pageIndex];
}

// 切换到指定的pageIndex所在的位置
- (void)switchToPage:(NSUInteger)pageIndex animated:(BOOL)animated {
    // 内部调用magicView的方法
    [self.magicView switchToPage:pageIndex animated:animated];
}


#pragma mark - accessor methods

// 核心view，创建magicView
- (VTMagicView *)magicView {
    if (!_magicView) {
        
        _magicView = [[VTMagicView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        _magicView.autoresizesSubviews = YES;
        
        // magicView的magicController设置为self
        _magicView.magicController = self;
        
        // 数据源和代理会被外部或者子类重新赋值
        _magicView.delegate = self;
        _magicView.dataSource = self;
        
        // 重新布局子控件
        [self.view setNeedsLayout];
    }
    return _magicView;
}

// 重写get方法，返回自控制器
- (NSArray<UIViewController *> *)viewControllers {
    return self.magicView.viewControllers;
}

#pragma mark - VTMagicViewDataSource

// 交给子类或者调用者去实现的协议
- (NSArray<NSString *> *)menuTitlesForMagicView:(VTMagicView *)magicView {
    return nil;
}

- (UIButton *)magicView:(VTMagicView *)magicView menuItemAtIndex:(NSUInteger)itemIndex {
    return nil;
}

- (UIViewController *)magicView:(VTMagicView *)magicView viewControllerAtPage:(NSUInteger)pageInde {
    return nil;
}

#pragma mark - VTMagicViewDelegate

// 交给子类或者调用者去实现的协议
- (void)magicView:(VTMagicView *)magicView viewDidAppear:(__kindof UIViewController *)viewController atPage:(NSUInteger)pageIndex {
    VTLog(@"index:%ld viewControllerDidAppear:%@", (long)pageIndex, viewController.view);
}

- (void)magicView:(VTMagicView *)magicView viewDidDisappear:(__kindof UIViewController *)viewController atPage:(NSUInteger)pageIndex {
    VTLog(@"index:%ld viewControllerDidDisappear:%@", (long)pageIndex, viewController.view);
}

- (void)magicView:(VTMagicView *)magicView didSelectItemAtIndex:(NSUInteger)itemIndex {
    VTLog(@"didSelectItemAtIndex:%ld", (long)itemIndex);
}

@end