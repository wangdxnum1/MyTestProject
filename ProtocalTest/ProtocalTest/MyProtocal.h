//
//  MyProtocal.h
//  ProtocalTest
//
//  Created by HaKim on 17/2/4.
//  Copyright © 2017年 haKim. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSString;
@protocol MyProtocal <NSObject>

@optional

@property (nonatomic, copy) NSString *name;

@required

@end
