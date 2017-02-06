//
//  ViewController.m
//  RACTest1
//
//  Created by HaKim on 16/4/18.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "ViewController.h"
#import "ReactiveCocoa.h"

typedef void (^RWSignInResponse)(BOOL);

@interface ViewController ()

@property (nonatomic, weak) UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (nonatomic, strong) RACSignal *signale;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UITextField *textField = [[UITextField alloc]initWithFrame:CGRectMake(50, 100, 300, 44)];
    [self.view addSubview:textField];
    self.textField = textField;
    textField.placeholder = @"测试";
    textField.borderStyle = UITextBorderStyleRoundedRect;
    //self.loginBtn.enabled = NO;
    
    [self test2];
    [self test3];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)test3{
//    [[self.loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
//        NSLog(@"btn clicked");
//    }];
    //__block RACSignal *signal = nil;
    __weak __block typeof(self.signale) weakSignal =  self.signale;
     [[[self.loginBtn
       rac_signalForControlEvents:UIControlEventTouchUpInside]
      map:^id(id value) {
          NSLog(@"loginBtn map");
          weakSignal = [self signInSignal];
          [weakSignal subscribeNext:^(id x) {
              NSLog(@"Sign in result: %@", x);
          }];
          return weakSignal;
      }] subscribeNext:^(id x) {
          NSLog(@"subscribeNext");
      }];
    
//    [[[self.loginBtn
//       rac_signalForControlEvents:UIControlEventTouchUpInside]
//      flattenMap:^RACStream *(id value){
//          NSLog(@"loginBtn map");
//          return[self signInSignal];
//      }]
//     subscribeNext:^(id x){
//         NSLog(@"Sign in result: %@", x);
//     }];
}

- (void)test2{
    RACSignal *signal = self.textField.rac_textSignal;
    RAC(self.textField,backgroundColor) = [signal map:^id(NSString *value) {
        return (value.length > 3) ? [UIColor orangeColor] : [UIColor clearColor];
    }];
}

- (void)test1{
    //    [self.textField.rac_textSignal subscribeNext:^(id x) {
    //        NSLog(@"%@",x);
    //    }];
    RACSignal *signal = self.textField.rac_textSignal;
    signal = [signal filter:^BOOL(id value) {
        NSString *text = value;
        return  text.length > 3;
    }];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
}

- (RACSignal *)signInSignal {
    return [RACSignal createSignal:^RACDisposable *(id subscriber){
        [self loginWithUserName:self.textField.text completion:^(BOOL success) {
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

- (void)loginWithUserName:(NSString *)name completion:(RWSignInResponse)block{
    NSLog(@"%s",__FUNCTION__);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL success = YES;
        if([name isEqualToString:@"wang"]){
            
        }else{
            success = NO;
        }
        if(block){
            block(success);
        }
    });
}

@end
