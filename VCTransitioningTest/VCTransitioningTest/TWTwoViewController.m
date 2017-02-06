//
//  TWTwoViewController.m
//  VCTransitioningTest
//
//  Created by HaKim on 16/8/11.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWTwoViewController.h"
#import "XWMagicMoveCell.h"
#import "TWThreeViewController.h"

static NSString * const reuseIdentifier = @"XWMagicMoveCell";

@interface TWTwoViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>



@end

@implementation TWTwoViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.title = @"push";
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([XWMagicMoveCell class]) bundle:nil] forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return 20;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    return [self.collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    self.currentIndexPath = indexPath;
    
    id delegate = self.navigationController.delegate;
    NSLog(@"%@",delegate);
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([TWThreeViewController class])];
    
    self.navigationController.delegate = vc;
    
    
    [self.navigationController pushViewController:vc animated:YES];
    
}

@end
