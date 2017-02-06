//
//  TestViewController.m
//  GCDTest
//
//  Created by HaKim on 16/1/29.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "TestViewController.h"
#import "AFNetworking.h"

@interface TestViewController ()

@property (nonatomic, strong) AFHTTPSessionManager *httpClient;

@property (nonatomic, copy) NSString *html;
@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _httpClient = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:@"http://www.sina.com"]];
    _httpClient.requestSerializer.timeoutInterval = 30;
    _httpClient.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    
    //取出reponseSerilizer可接受的内容类型集合
    NSMutableSet *set = [NSMutableSet setWithSet:_httpClient.responseSerializer.acceptableContentTypes];
    //增加类型
    [set addObject:@"text/plain"];
    [set addObject:@"text/html"];
    //设回去
    _httpClient.responseSerializer.acceptableContentTypes = [set copy];
    
    _httpClient.responseSerializer = [AFHTTPResponseSerializer serializer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)downloadBtnClicked:(UIButton *)sender {
    [self loadHtmlFromServer];
}

- (void)loadHtmlFromServer
{
    [self.httpClient GET:@"" parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

        self.html = [[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"%@",self.html);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
}

- (void)dealloc
{
    NSLog(@"%@ is released",self);
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
