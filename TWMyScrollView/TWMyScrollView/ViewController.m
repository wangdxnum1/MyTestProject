//
//  ViewController.m
//  TWMyScrollView
//
//  Created by HaKim on 2017/4/28.
//  Copyright © 2017年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "TWMyScrollView.h"
#import "TWTestView.h"
#import "TWZhiRefreshHeader.h"

@interface ViewController ()

//@property (nonatomic, weak) TWMyScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
//    TWMyScrollView *scrollView = [[TWMyScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    [self.view addSubview:scrollView];
    
//    TWTestView *view = [[TWTestView alloc] initWithFrame:CGRectMake(0, -44, [UIScreen mainScreen].bounds.size.width, 44)];
////    view.backgroundColor = [UIColor orangeColor];
//    [self.tableView addSubview:view];
    
    self.tableView.mj_header = [TWZhiRefreshHeader headerWithRefreshingBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tableView.mj_header endRefreshing];
        });
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView 的 UITableViewDelegate 和 UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"testCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"测试数据 %@",@(indexPath.row)];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}
@end
