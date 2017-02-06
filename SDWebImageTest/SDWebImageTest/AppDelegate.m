//
//  AppDelegate.m
//  SDWebImageTest
//
//  Created by HaKim on 16/7/5.
//  Copyright © 2016年 haKim. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    __block UIBackgroundTaskIdentifier background_task;
    //注册一个后台任务，告诉系统我们需要向系统借一些事件
//    background_task = [application beginBackgroundTaskWithExpirationHandler:^ {
//        
//        //不管有没有完成，结束background_task任务
//        [application endBackgroundTask: background_task];
//        background_task = UIBackgroundTaskInvalid;
//    }];
    
    //异步
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //### background task starts
        NSLog(@"Running in the background\n");
        
        static int i = 0;
        while(i < 100000000)
        {
            NSLog(@"Background time Remaining: %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
            [NSThread sleepForTimeInterval:1]; //wait for 1 sec
            i++;
        }
        
        //我们自己完成任务后，结束background_task任务
        //如果我们用while（TRUE）的话，下面这两行代码应该不会执行
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
