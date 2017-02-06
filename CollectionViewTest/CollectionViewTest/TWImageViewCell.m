//
//  TWImageViewCell.m
//  CollectionViewTest
//
//  Created by 胡金丽 on 16/8/14.
//  Copyright © 2016年 Tim. All rights reserved.
//

#import "TWImageViewCell.h"

@interface TWImageViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageVew;

@end

@implementation TWImageViewCell

- (void)setImageName:(NSString *)imageName{
    _imageName = [imageName copy];
    
    self.imageVew.image =[UIImage imageNamed:imageName];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.layer.borderColor = [UIColor whiteColor].CGColor;
    self.layer.borderWidth = 8;
}

@end
