//
//  TWTestViewController.m
//  VTMagicTest
//
//  Created by HaKim on 16/6/24.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TWTestViewController.h"
#import "UIColor+randomColor.h"

@interface TWTestViewController ()

@end

@implementation TWTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor randomColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
