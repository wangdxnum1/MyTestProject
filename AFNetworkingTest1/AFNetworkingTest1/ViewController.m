//
//  ViewController.m
//  AFNetworkingTest1
//
//  Created by HaKim on 16/8/3.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"

@interface ViewController ()

@property (nonatomic, strong) AFHTTPSessionManager *manager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[[NSURL alloc] initWithString:@"http://www.baidu.com"]];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //取出reponseSerilizer可接受的内容类型集合
    NSMutableSet *set = [NSMutableSet setWithSet:manager.responseSerializer.acceptableContentTypes];
    //增加类型
    [set addObject:@"text/plain"];
    [set addObject:@"text/html"];
    [set addObject:@"application/json"];
    //设回去
    manager.responseSerializer.acceptableContentTypes = [set copy];
    
    self.manager = manager;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.manager GET:@"" parameters:nil progress:nil
         success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//             NSLog(@"%@" ,responseObject);
             NSString *html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
             NSLog(@"%@",html);
             NSError *error = nil;
             [html writeToFile:@"/Users/hikim/Desktop/baidu.html" atomically:YES encoding:NSUTF8StringEncoding error:&error];
             NSLog(@"error = %@",error);
         } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
             NSLog(@"%@", error);
         }];
}

@end
