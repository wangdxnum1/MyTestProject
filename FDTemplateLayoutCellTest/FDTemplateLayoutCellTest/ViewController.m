//
//  ViewController.m
//  FDTemplateLayoutCellTest
//
//  Created by HaKim on 16/2/1.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "HDPictureViewCell.h"
#import "UITableView+FDTemplateLayoutCell.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.tableView.fd_debugLogEnabled = YES;
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([HDPictureViewCell class]) bundle:nil];
    
    [self.tableView registerNib:nib forCellReuseIdentifier:NSStringFromClass([HDPictureViewCell class])];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView 的 UITableViewDelegate 和 UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 44;
//}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [tableView fd_heightForCellWithIdentifier:NSStringFromClass([HDPictureViewCell class]) configuration:^(HDPictureViewCell *cell) {
        cell.fd_enforceFrameLayout = NO;
        cell.text = @"这个 cell 只为了参加高度计算，不会真的显示到屏幕上；它通过 UITableView 的 -dequeueCellForReuseIdentifier: 方法 lazy 创建并保存，所以要求这个 ReuseID 必须已经被注册到了 UITableView 中，也就是说，要么是 Storyboard 中的原型 cell，要么就是使用了 UITableView 的 -registerClass:forCellReuseIdentifier: 或 -registerNib:forCellReuseIdentifier:其中之一的注册方法。";
    }];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    static NSString *cellID = @"testCellID";
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
//    if(cell == nil)
//    {
//        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
//    }
//    cell.textLabel.text = @"测试数据";
    
    HDPictureViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([HDPictureViewCell class])];
    if(cell == nil)
    {
        cell = [[HDPictureViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([HDPictureViewCell class])];
    }
    cell.text = @"这个 cell 只为了参加高度计算，不会真的显示到屏幕上；它通过 UITableView 的 -dequeueCellForReuseIdentifier: 方法 lazy 创建并保存，所以要求这个 ReuseID 必须已经被注册到了 UITableView 中，也就是说，要么是 Storyboard 中的原型 cell，要么就是使用了 UITableView 的 -registerClass:forCellReuseIdentifier: 或 -registerNib:forCellReuseIdentifier:其中之一的注册方法。";
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
