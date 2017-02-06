//
//  UIImage+MultiFormat.h
//  SDWebImage
//
//  Created by Olivier Poitrey on 07/06/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>

// UIImage 的分类
@interface UIImage (MultiFormat)

// 根据data生成UIImage对象
+ (UIImage *)sd_imageWithData:(NSData *)data;

@end
