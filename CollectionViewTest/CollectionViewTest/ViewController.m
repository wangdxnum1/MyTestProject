//
//  ViewController.m
//  CollectionViewTest
//
//  Created by 胡金丽 on 16/8/14.
//  Copyright © 2016年 Tim. All rights reserved.
//

#import "ViewController.h"
#import "TWImageViewCell.h"
#import "TWMovieFlowLayout.h"
#import "TWCirCleLayout.h"

@interface ViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, weak) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray *imageNames;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupCollectionView];
}

- (void)setupCollectionView{
    TWCirCleLayout *flow = [[TWCirCleLayout alloc] init];
    
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 160, self.view.frame.size.width, 200) collectionViewLayout:flow];
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
    collectionView.delegate = self;
    collectionView.dataSource = self;
//    collectionView.backgroundColor = [UIColor whiteColor];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([UICollectionViewCell class])];
    
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([TWImageViewCell class]) bundle:nil] forCellWithReuseIdentifier:NSStringFromClass([TWImageViewCell class])];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"%@",NSStringFromCGRect(self.collectionView.bounds));
    if([self.collectionView.collectionViewLayout isMemberOfClass:[TWMovieFlowLayout class]]){
        [self.collectionView setCollectionViewLayout:[[TWCirCleLayout alloc] init] animated:YES];
    }else{
        TWMovieFlowLayout *flow = [[TWMovieFlowLayout alloc] init];
        flow.itemSize = CGSizeMake(100, 100);
        flow.minimumInteritemSpacing = 16;
        [self.collectionView setCollectionViewLayout:flow animated:YES];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.imageNames.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
//    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([UICollectionViewCell class]) forIndexPath:indexPath];
//    cell.backgroundColor = [UIColor orangeColor];
    
    TWImageViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([TWImageViewCell class]) forIndexPath:indexPath];

    cell.imageName = [self.imageNames objectAtIndex:indexPath.item];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self.imageNames removeObjectAtIndex:indexPath.item];
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
}

- (NSMutableArray*)imageNames{
    if(_imageNames == nil){
        _imageNames = [NSMutableArray arrayWithCapacity:20];
        for (int i = 0; i < 20; ++i) {
            NSString *imageName = [NSString stringWithFormat:@"%@",@(i + 1)];
            [_imageNames addObject:imageName];
        }
    }
    return _imageNames;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
