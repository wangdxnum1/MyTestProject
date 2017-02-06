//
//  TWCirCleLayout.m
//  CollectionViewTest
//
//  Created by 胡金丽 on 16/8/14.
//  Copyright © 2016年 Tim. All rights reserved.
//

#import "TWCirCleLayout.h"

@interface TWCirCleLayout ()

@property (nonatomic, strong) NSMutableArray *attris;

@end

@implementation TWCirCleLayout

- (void)prepareLayout{
    [super prepareLayout];
    [self.attris removeAllObjects];
    
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    return YES;
}

- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect{
    
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    for (int i = 0; i < count; ++i) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        
        [_attris addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
    }
    return self.attris;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    CGFloat circleX = self.collectionView.frame.size.width * 0.5;
    CGFloat circleY = self.collectionView.frame.size.height * 0.5;
    
    CGFloat radius = 70;
    
    UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    
    CGFloat angle = ((2 * M_PI)/[self.collectionView numberOfItemsInSection:0]) * indexPath.item;
    attr.size  = CGSizeMake(50, 50);
    CGFloat x = circleX + cos(angle) * radius;
    CGFloat y = circleY + sin(angle) * radius;
    
    attr.center = CGPointMake(x, y);
    return attr;
}


- (NSMutableArray*)attris{
    if(_attris == nil){
        _attris = [NSMutableArray array];
    }
    return _attris;
}

@end
