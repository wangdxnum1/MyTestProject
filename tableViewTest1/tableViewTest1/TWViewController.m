//
//  TWViewController.m
//  tableViewTest1
//
//  Created by twang on 12/12/15.
//  Copyright (c) 2015 twang. All rights reserved.
//

#import "TWViewController.h"
#import "UIImage+Color.h"

static CGFloat maxH = 124;
@interface TWViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) UIRefreshControl *refreshControl;
@property (weak, nonatomic) UIButton *btn;
@property (weak, nonatomic) UIImageView *imageView;
@property (assign, nonatomic) BOOL btnShow;

//CGFloat TopBorder = Height/4;
//CGFloat BtnH = Height/20;
//CGFloat ImageH = TopBorder - BtnH;
@property (nonatomic, assign) CGFloat TopBorder;
@property (nonatomic, assign) CGFloat BtnH;
@property (nonatomic, assign) CGFloat ImageH;
@property (nonatomic, assign) CGFloat Width;
@property (nonatomic, assign) CGFloat Height;
@end

@implementation TWViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self setupGlobalVarible];
    self.tableView.contentInset = UIEdgeInsetsMake(self.TopBorder, 0, 0, 0);
    self.tableView.backgroundColor = [UIColor redColor];
    
    [self setupImageView];
    [self setupBtn];
}

- (void)setupRefreshCtrl
{
    UIRefreshControl *ctrl = [[UIRefreshControl alloc] init];
    self.refreshControl = ctrl;
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"努力加载中……"];
    self.refreshControl.tintColor = [UIColor grayColor];
    [self.refreshControl addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView addSubview:self.refreshControl];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY < -self.BtnH) {
        //按钮淡入效果
        //self.btn.alpha = offsetY/maxH;
        CGRect frame = self.btn.frame;
        frame.origin.y = -offsetY - self.BtnH;
        self.btn.frame = frame;
        
        frame = self.imageView.frame;
        frame.origin.y = -(self.TopBorder + offsetY);
        self.imageView.frame = frame;
        
        return;
    }else if(self.btn.frame.origin.y != 0)
    {
        CGRect frame = self.btn.frame;
        frame.origin.y = 0;
        self.btn.frame = frame;
        
        frame = self.imageView.frame;
        frame.origin.y = -self.ImageH;
        self.imageView.frame = frame;
    }
    
//    if (self.btnShow) {
//        //按钮停留顶部
//        //askBtn.frame.origin.y = -offsetY
//        return;
//    }
//    self.tableView.contentInset = UIEdgeInsetsMake(maxH, 0, 0, 0);
//    //self.refreshControl = refreshCtrl
//    self.btn.alpha = 1;
//    self.btnShow = true;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"test = %@",@(indexPath.row)];
    return cell;
}
- (IBAction)btnClicked:(UIBarButtonItem *)sender {
    
    CGRect screenFrame = [UIScreen mainScreen].bounds;
    
    CGRect boundsFrame = self.tableView.bounds;
    
    CGRect tableViewFrame = self.tableView.frame;
    
    CGPoint contentOffset = self.tableView.contentOffset;
    
    UIEdgeInsets contentInset = self.tableView.contentInset;
    
    CGRect refreshCtrlFrame = self.refreshControl.frame;
    
    NSLog(@"%@",self.tableView);
}

- (void)refreshAction
{

}

- (UIButton*)createBtn
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    UIImage *image = [UIImage imageWithColor:[UIColor yellowColor]];
    [btn setBackgroundImage:image forState:UIControlStateNormal];
    [btn setTitle:@"马上提问" forState:UIControlStateNormal];
    return btn;
}

- (void)setupGlobalVarible
{
    CGRect MainBounds = [UIScreen mainScreen].bounds;
    self.Width = MainBounds.size.width;
    self.Height = MainBounds.size.height;
    self.TopBorder = self.Height/4;
    self.BtnH = self.Height/20;
    self.ImageH = self.TopBorder - self.BtnH;
}

- (void)setupImageView
{
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.Width, self.ImageH)];
    self.imageView = imageView;
    self.imageView.backgroundColor = [UIColor greenColor];
    
    [self.view addSubview:self.imageView];
}

- (void)setupBtn
{
    UIButton *btn = [self createBtn];
    CGFloat btnY = self.TopBorder - self.BtnH;
    
    btn.frame = CGRectMake(0, btnY, self.Width, self.BtnH);
    self.btn = btn;
    [self.view addSubview:btn];
}
@end
