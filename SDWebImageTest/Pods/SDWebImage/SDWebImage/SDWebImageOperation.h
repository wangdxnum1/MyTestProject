/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>

// 定义了一个Operation协议，支持cancel接口
@protocol SDWebImageOperation <NSObject>

- (void)cancel;

@end
