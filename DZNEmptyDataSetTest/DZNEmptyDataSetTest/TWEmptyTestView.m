//
//  TWEmptyTestView.m
//  DZNEmptyDataSetTest
//
//  Created by HaKim on 16/12/21.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWEmptyTestView.h"

@implementation TWEmptyTestView

+ (instancetype)emptyTestView{
    NSBundle *bundle=[NSBundle mainBundle];
    NSArray *objs=[bundle loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    return [objs lastObject];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

//- (CGSize)intrinsicContentSize
//{
//    return CGSizeMake(375, 200);
//}

- (void)awakeFromNib{
    [super awakeFromNib];
}

@end
