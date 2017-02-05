//
//  TWPersion.m
//  ProtocalTest
//
//  Created by HaKim on 17/2/4.
//  Copyright © 2017年 haKim. All rights reserved.
//

#import "TWPersion.h"

@implementation TWPersion
@synthesize name = _name;

- (NSString*)description{
    return [NSString stringWithFormat:@"%@",self.name];
}

@end
