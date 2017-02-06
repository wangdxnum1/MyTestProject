//
//  ViewController.m
//  TWKLCPopupTest
//
//  Created by HaKim on 16/2/19.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "KLCPopup.h"

#pragma mark - Categories

@implementation UIColor (KLCPopupExample)

+ (UIColor*)klcLightGreenColor {
    return [UIColor colorWithRed:(184.0/255.0) green:(233.0/255.0) blue:(122.0/255.0) alpha:1.0];
}

+ (UIColor*)klcGreenColor {
    return [UIColor colorWithRed:(0.0/255.0) green:(204.0/255.0) blue:(134.0/255.0) alpha:1.0];
}
@end


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self show];
}

- (void)show{
    // Generate content view to present
    UIView* contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.backgroundColor = [UIColor klcLightGreenColor];
    contentView.layer.cornerRadius = 12.0;
    
    UILabel* dismissLabel = [[UILabel alloc] init];
    dismissLabel.translatesAutoresizingMaskIntoConstraints = NO;
    dismissLabel.backgroundColor = [UIColor clearColor];
    dismissLabel.textColor = [UIColor whiteColor];
    dismissLabel.font = [UIFont boldSystemFontOfSize:72.0];
    dismissLabel.text = @"Hi.";
    
    UIButton* dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissButton.translatesAutoresizingMaskIntoConstraints = NO;
    dismissButton.contentEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20);
    dismissButton.backgroundColor = [UIColor klcGreenColor];
    [dismissButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [dismissButton setTitleColor:[[dismissButton titleColorForState:UIControlStateNormal] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    dismissButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0];
    [dismissButton setTitle:@"Bye" forState:UIControlStateNormal];
    dismissButton.layer.cornerRadius = 6.0;
    [dismissButton addTarget:self action:@selector(dismissButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [contentView addSubview:dismissLabel];
    [contentView addSubview:dismissButton];
    
    NSDictionary* views = NSDictionaryOfVariableBindings(contentView, dismissButton, dismissLabel);
    
    [contentView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(16)-[dismissLabel]-(10)-[dismissButton]-(24)-|"
                                             options:NSLayoutFormatAlignAllCenterX
                                             metrics:nil
                                               views:views]];
    
    [contentView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(36)-[dismissLabel]-(36)-|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    
    
    // 默认的动画效果配置
    //KLCPopup *popup = [KLCPopup popupWithContentView:contentView];
    
    // 自定义动画效果的popup
    KLCPopup *popup = [KLCPopup popupWithContentView:contentView
                                            showType:KLCPopupShowTypeBounceIn
                                         dismissType:KLCPopupDismissTypeFadeOut
                                            maskType:KLCPopupMaskTypeGradient
                            dismissOnBackgroundTouch:NO
                               dismissOnContentTouch:NO];
    //popup.backGroundViewColor = [UIColor whiteColor];
    popup.dismissAnimationTime = 0.6;
    
    // 自定义位置
    KLCPopupLayout layout = KLCPopupLayoutMake(KLCPopupHorizontalLayoutLeft, KLCPopupVerticalLayoutBottom);
    
    
    // 显示show的函数
    
    // 1 默认动画
    //[popup show];
    
    // 2 默认动画，但是0.3秒以后消失
    //[popup showWithDuration:0.3];
    
    // 3 在指定位置显示
    //[popup showAtCenter:CGPointMake(100, 100) inView:self.view];
    
    // 4自定义位置显示
    [popup showWithLayout:layout];
}

- (void)dismissButtonPressed:(id)sender {
    if ([sender isKindOfClass:[UIView class]]) {
        [(UIView*)sender dismissPresentingPopup];
    }
}

@end



