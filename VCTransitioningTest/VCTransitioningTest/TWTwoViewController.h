//
//  TWTwoViewController.h
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TWTwoViewController : UIViewController

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end
