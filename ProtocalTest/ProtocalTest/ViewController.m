//
//  ViewController.m
//  ProtocalTest
//
//  Created by HaKim on 17/2/4.
//  Copyright © 2017年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "TWPersion.h"

@interface ViewController ()



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    TWPersion *p = [[TWPersion alloc] init];
    p.name = @"wang";
    NSLog(@"%@",p.description);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
