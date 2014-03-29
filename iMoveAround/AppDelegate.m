//
//  AppDelegate.m
//  iMoveAround
//
//  Created by Karl Gallagher on 3/1/14.
//  Copyright (c) 2014 Karl Gallagher. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunchingWithOptions called.");
    // Override point for customization after application launch.
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    //    [self triggerAlert:application alertString:@"applicationWillResignActive!" ];
    
    NSLog(@"applicationWillResignActive called.");

    if (countDownTimer != nil)
    {
//        NSLog(@"applicationWillResignActive: Timer still going, add background task!");
//        __block UIBackgroundTaskIdentifier bgTask = 0;
//        UIApplication  *app = [UIApplication sharedApplication];
////        NSLog(@"bgTask: %lu", (unsigned long)bgTask);
//        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
//            [app endBackgroundTask:bgTask];
//        }];
//        NSLog(@"bgTask after: %lu", (unsigned long)bgTask);
    }
    else
        NSLog(@"applicationWillResignActive: Timer isn't running, allow background!");
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    //    [self triggerAlert:application alertString:@"applicationDidEnterBackground!" ];
    //    [self triggerNotification:application alertString:@"applicationDidEnterBackground!" ];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    NSLog(@"applicationDidEnterBackground called.");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //    [self triggerAlert:application alertString:@"applicationWillEnterForeground!" ];
    //    [self triggerNotification:application alertString:@"applicationWillEnterForeground!" ];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground called.");
}

- (void)triggerAlert:(UIApplication *)application alertString:(NSString *)alertString
{
    UIAlertView *alertDialog;
    alertDialog = [[UIAlertView alloc]
                   initWithTitle: @"Yawn!"
                   message:alertString
                   delegate: nil
                   cancelButtonTitle: @"Welcome Back"
                   otherButtonTitles: nil];
    [alertDialog show];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[UIApplication sharedApplication] clearKeepAliveTimeout];
    NSLog(@"applicationDidBecomeActive called.");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"applicationWillTerminate called.");
    triggerNotification:[NSString stringWithFormat:@"App is being terminated!"];
}


@end
