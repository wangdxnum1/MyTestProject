//
//  TWOneViewController.h
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TWOneViewControllerDelegate <NSObject>

@optional
- (void)oneViewControllerDidClickedMissBtn:(UIButton*)btn;

@end

@interface TWOneViewController : UIViewController

@property (nonatomic, weak) id<TWOneViewControllerDelegate> delegate;

@end
