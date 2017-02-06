//
//  ViewController.m
//  GCDTest
//
//  Created by HaKim on 16/1/28.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"

@interface ViewController ()
{
    dispatch_queue_t _myConcurrentQueue;
    dispatch_queue_t _myserialQueue;
    dispatch_group_t _group;
}

@property (nonatomic, strong) AFHTTPSessionManager *httpClient;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
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
    
    
    _myConcurrentQueue = dispatch_queue_create("test.concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    _myserialQueue = dispatch_queue_create("test.serial.queue", DISPATCH_QUEUE_SERIAL);
    _group = dispatch_group_create();
    
    
    //[self test5];
    
    [self test7];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)test8
{
    NSLog(@"%@ 开始下载",[NSThread currentThread]);
    
    dispatch_apply(30, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t i) {
        //NSLog(@"dispatch_apply %li ---- %@",i ,[NSThread currentThread]);
            dispatch_group_enter(_group);
            [self run3WithIndex:i];
    });
    
    dispatch_group_notify(_group, dispatch_get_main_queue(), ^{
        NSLog(@"%@ 主线程 做事情",[NSThread currentThread]);
    });
    
    NSLog(@"%@ 开始下载返回",[NSThread currentThread]);
}

- (void)test7
{
    NSLog(@"%@ 开始下载",[NSThread currentThread]);

    for(int i = 0; i < 30; ++i)
    {
        dispatch_group_enter(_group);
        [self run2];
    }
    
    dispatch_group_notify(_group, dispatch_get_main_queue(), ^{
        NSLog(@"%@ 主线程 做事情",[NSThread currentThread]);
    });
    
    NSLog(@"%@ 开始下载返回",[NSThread currentThread]);
}

- (void)test6
{
    NSLog(@"%@ 开始下载",[NSThread currentThread]);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"%@ 开启下载任务的线程，会被阻塞一定时间",[NSThread currentThread]);
        
        
        
        for(int i = 0; i < 30; ++i)
        {
            dispatch_group_enter(_group);
            [self run2];
        }
        
        NSLog(@"%@ dispatch_group_wait",[NSThread currentThread]);
        dispatch_group_wait(_group, DISPATCH_TIME_FOREVER);
        
        dispatch_group_notify(_group, dispatch_get_main_queue(), ^{
            NSLog(@"%@ 主线程 做事情",[NSThread currentThread]);
        });
        
        NSLog(@"%@ 等待返回",[NSThread currentThread]);
    });
}

- (void)run3WithIndex:(NSInteger)i
{
    NSLog(@"%li do work in thread %@",i,[NSThread currentThread]);
    [self.httpClient GET:@"" parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //NSLog(@"%@",downloadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //NSString *html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"下载成功");
        
        dispatch_group_leave(_group);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_group_leave(_group);
        NSLog(@"%@",error);
    }];
}

- (void)run2
{
    NSLog(@"do work in thread %@",[NSThread currentThread]);
    [self.httpClient GET:@"" parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        //NSLog(@"%@",downloadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //NSString *html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"下载成功");
        
        dispatch_group_leave(_group);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        dispatch_group_leave(_group);
        NSLog(@"%@",error);
    }];
}

- (void)test5
{
    _myConcurrentQueue = dispatch_queue_create("test.concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    _myserialQueue = dispatch_queue_create("test.serial.queue", DISPATCH_QUEUE_SERIAL);
    for(int i = 0; i < 10; ++i)
    {
        dispatch_async(_myConcurrentQueue, ^{
            [self run1:i];
        });
    }
}

- (void)run1:(NSInteger )i
{
//    for(int i = 0; i < 10; ++i)
//    {
//        NSLog(@"do work %i ---- %@ ",i,[NSThread currentThread]);
//    }
    dispatch_sync(_myserialQueue, ^{
        for(int i = 0; i < 10; ++i)
        {
            NSLog(@"do work %i ---- %@ ",i,[NSThread currentThread]);
        }
    });
}

- (void)test4
{
    _myConcurrentQueue = dispatch_queue_create("test.serial.queue", DISPATCH_QUEUE_SERIAL);
    NSLog(@"=================1");
    dispatch_sync(_myConcurrentQueue, ^{
        NSLog(@"=================2");
    });
    NSLog(@"=================3");
}

- (void)test3
{
    NSLog(@"=================4");
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"=================5");
    });
    NSLog(@"=================6");
}

- (void)test2
{
    _myConcurrentQueue = dispatch_queue_create("test.concurrent.queue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_sync(_myConcurrentQueue, ^{
        NSLog(@"do work with dispatch_sync %@",[NSThread currentThread]);
    });
    
    NSLog(@"test2 over------ %@",[NSThread currentThread]);
}

- (void)test1
{
    _myConcurrentQueue = dispatch_queue_create("test.concurrent.queue", DISPATCH_QUEUE_CONCURRENT);

    dispatch_async(_myConcurrentQueue, ^{
        for(int i = 0; i < 10; ++i)
        {
            NSLog(@"do work 1 ---- %@ ",[NSThread currentThread]);
        }
    });
    
    dispatch_async(_myConcurrentQueue, ^{
        for(int i = 0; i < 10; ++i)
        {
            NSLog(@"do work 2 ---- %@ ",[NSThread currentThread]);
        }
    });
    
    dispatch_barrier_async(_myConcurrentQueue, ^{
        for(int i = 0; i < 10; ++i){
            NSLog(@"do work with barrier ---- %@ ",[NSThread currentThread]);
        }
        
    });
    
    dispatch_async(_myConcurrentQueue, ^{
        for(int i = 0; i < 10; ++i)
        {
            NSLog(@"do work 3 ---- %@ ",[NSThread currentThread]);
        }
    });
    
    dispatch_async(_myConcurrentQueue, ^{
        for(int i = 0; i < 10; ++i)
        {
            NSLog(@"do work 4 ---- %@ ",[NSThread currentThread]);
        }
    });
}

@end
