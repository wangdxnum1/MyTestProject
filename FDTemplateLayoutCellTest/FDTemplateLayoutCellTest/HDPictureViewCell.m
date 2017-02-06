//
//  HDPictureViewCell.m
//  FDTemplateLayoutCellTest
//
//  Created by HaKim on 16/2/1.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "HDPictureViewCell.h"

@interface HDPictureViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *conentLabel;

@end

@implementation HDPictureViewCell


- (void)setText:(NSString *)text
{
    self.conentLabel.text = text;
}
- (void)awakeFromNib {
    // Initialization code
    
    self.contentView.bounds = [UIScreen mainScreen].bounds;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
