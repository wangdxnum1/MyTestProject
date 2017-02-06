//
//  ViewController.m
//  VTMagicTest
//
//  Created by HaKim on 16/6/23.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "VTMagic.h"
#import "UIColor+randomColor.h"
#import "TWTestViewController.h"

@interface ViewController ()<VTMagicViewDataSource,VTMagicViewDelegate,VTMagicReuseProtocol>

@property (nonatomic, strong) VTMagicController *magicController;

@property (nonatomic, copy) NSArray *menuList;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _menuList = @[@"最新",@"热门",@"本地",@"体育",@"娱乐",@"最新",@"热门",@"本地",@"体育",@"娱乐"];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationController.navigationBar.translucent = YES;
    
    [self addChildViewController:self.magicController];
    [self.view addSubview:self.magicController.view];
    [self.magicController didMoveToParentViewController:self];
    
    [self.magicController.magicView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (VTMagicController *)magicController
{
    if (!_magicController) {
        VTMagicController *magicController = [[VTMagicController alloc] init];
        _magicController = magicController;
        _magicController.magicView.navigationColor = [UIColor whiteColor];
        _magicController.magicView.sliderColor = [UIColor redColor];
        
        _magicController.magicView.layoutStyle = VTLayoutStyleDefault;
        _magicController.magicView.switchStyle = VTSwitchStyleDefault;
        _magicController.magicView.navigationHeight = 44.f;
        
        _magicController.magicView.dataSource = self;
        _magicController.magicView.delegate = self;
        
        
        _magicController.magicView.frame = CGRectMake(0, 0, 320, self.view.frame.size.height - 64);
        
//        _magicController.magicView.separatorHeight = 10;
//        _magicController.magicView.separatorView.backgroundColor = [UIColor randomColor];
        
//        _magicController.magicView.headerView.backgroundColor = [UIColor randomColor];
//        _magicController.magicView.headerHidden = NO;
        
//        _magicController.magicView.navigationView.hidden = YES;
    }
    return _magicController;
}

- (NSArray<NSString *> *)menuTitlesForMagicView:(VTMagicView *)magicView
{
    return self.menuList;
}

- (UIButton *)magicView:(VTMagicView *)magicView menuItemAtIndex:(NSUInteger)itemIndex
{
    static NSString *itemIdentifier = @"itemIdentifier";
    UIButton *menuItem = [magicView dequeueReusableItemWithIdentifier:itemIdentifier];
    if (!menuItem) {
        menuItem = [UIButton buttonWithType:UIButtonTypeCustom];
        [menuItem setTitleColor:RGBCOLOR(50, 50, 50) forState:UIControlStateNormal];
        [menuItem setTitleColor:RGBCOLOR(169, 37, 37) forState:UIControlStateSelected];
        menuItem.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:16.f];
    }
    return menuItem;
}

- (UIViewController *)magicView:(VTMagicView *)magicView viewControllerAtPage:(NSUInteger)pageIndex
{
    static NSString *recomId = @"recom.identifier";
    TWTestViewController *recomViewController = [magicView dequeueReusablePageWithIdentifier:recomId];
    if (!recomViewController) {
        recomViewController = [[TWTestViewController alloc] init];
    }
    return recomViewController;
}

- (void)magicView:(VTMagicView *)magicView didSelectItemAtIndex:(NSUInteger)itemIndex{
    NSLog(@"%@ %@",self.magicController.magicView,NSStringFromCGRect(self.magicController.magicView.frame));
}

//- (NSArray*)menuList{
//    if(_menuList == nil){
//        _menuList = @[@"最新",@"热门",@"本地",@"体育",@"娱乐"];
//    }
//    return _menuList;
//}

@end
