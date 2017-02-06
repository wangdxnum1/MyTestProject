//
//  TWMovieFlowLayout.m
//  CollectionViewTest
//
//  Created by 胡金丽 on 16/8/14.
//  Copyright © 2016年 Tim. All rights reserved.
//

#import "TWMovieFlowLayout.h"

@implementation TWMovieFlowLayout

- (void)prepareLayout{
    [super prepareLayout];
    
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    CGFloat offset = self.collectionView.frame.size.width * 0.5 - self.itemSize.width * 0.5;
    
    UIEdgeInsets insets = UIEdgeInsetsMake(0, offset, 0, offset);
    self.sectionInset = insets;
}
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    return YES;
}

- (nullable NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect{
    
    NSArray *array = [super layoutAttributesForElementsInRect:rect];
    
    CGFloat collectionviewCenterX = self.collectionView.frame.size.width * 0.5 + self.collectionView.contentOffset.x;
    
    for (UICollectionViewLayoutAttributes *attr in array) {
        CGFloat centerX = attr.center.x;
        CGFloat diff = ABS(collectionviewCenterX - centerX);
        
        CGFloat scale = 1.0 - diff / (self.collectionView.frame.size.width * 0.5);
        attr.transform = CGAffineTransformMakeScale(scale, scale);
    }
    
    return array;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity{
    
    CGFloat collectionviewCenterX = self.collectionView.frame.size.width * 0.5 + proposedContentOffset.x;
    
    // 计算出最终显示的矩形框
    CGRect rect;
    rect.origin.y = 0;
    rect.origin.x = proposedContentOffset.x;
    rect.size = self.collectionView.frame.size;
    // 获得super已经计算好的布局属性
    NSArray *array = [super layoutAttributesForElementsInRect:rect];
    
    
    CGFloat minDistance = CGFLOAT_MAX;
    for (UICollectionViewLayoutAttributes *attr in array) {
        CGFloat centerX = attr.center.x;
        CGFloat diff = centerX - collectionviewCenterX;
        if(ABS(minDistance) > ABS(diff)){
            minDistance = diff;
        }
    }
    
    proposedContentOffset.x += minDistance;
    
    return proposedContentOffset;
}

@end
