//
//  TWMyScrollView.m
//  TWMyScrollView
//
//  Created by HaKim on 2017/4/28.
//  Copyright © 2017年 haKim. All rights reserved.
//

#import "TWMyScrollView.h"

@interface TWMyScrollView ()

@property (assign,nonatomic) CGSize contentSize;

@end

@implementation TWMyScrollView

-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self commonInit];
        
        UIPanGestureRecognizer *panGesture=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePanGesture:)];
        [self addGestureRecognizer:panGesture];
        
        
        self.contentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height * 1.5);
        
    }
    return self;
}

-(void)handlePanGesture:(UIPanGestureRecognizer *)panGestureRecongnizer{
    CGPoint translation = [panGestureRecongnizer translationInView:self];
    
    NSLog(@"translation = %@",NSStringFromCGPoint(translation));
    
    CGRect bounds = self.bounds;
    
    //需要设置contentsize
    CGFloat newBoundsOriginX = bounds.origin.x - translation.x;
    CGFloat minBoundsOriginX = 0.0;
    CGFloat maxBoundsOriginX = self.contentSize.width - bounds.size.width;
    bounds.origin.x = fmax(minBoundsOriginX, fmin(newBoundsOriginX, maxBoundsOriginX));
    
    CGFloat newBoundsOriginY = bounds.origin.y - translation.y;
    CGFloat minBoundsOriginY = 0.0;
    CGFloat maxBoundsOriginY = self.contentSize.height - bounds.size.height;
    bounds.origin.y = fmax(minBoundsOriginY, fmin(newBoundsOriginY, maxBoundsOriginY));
    
    self.bounds = bounds;
    [panGestureRecongnizer setTranslation:CGPointZero inView:self];
}

- (void)commonInit{
    UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 100, 100)];
    redView.backgroundColor = [UIColor redColor];
    
    UIView *greenView = [[UIView alloc] initWithFrame:CGRectMake(160, 150, 150, 180)];
    greenView.backgroundColor = [UIColor greenColor];
    
    UIView *blueView = [[UIView alloc] initWithFrame:CGRectMake(60, 400, 200, 150)];
    blueView.backgroundColor = [UIColor blueColor];
    
    UIView *yellowView = [[UIView alloc] initWithFrame:CGRectMake(180, 600, 180, 200)];
    yellowView.backgroundColor = [UIColor yellowColor];
    
    [self addSubview:redView];
    [self addSubview:greenView];
    [self addSubview:blueView];
    [self addSubview:yellowView];
}

@end
