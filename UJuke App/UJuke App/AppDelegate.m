//
//  AppDelegate.m
//  UJuke
//
//  Created by Mohammed Kheder on 4/22/14.
//  Copyright (c) 2014 Mohammed Kheder. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //Makes the gold tint color in the tab bar
    _window.tintColor = [UIColor colorWithRed:241.0/255.0 green:184.0/255.0 blue:45.0/255.0 alpha:1];
    
    //To make the status bar black
    #define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        UIView *view=[[UIView alloc] initWithFrame:CGRectMake(0, 0,320, 20)];
        //view.backgroundColor=[UIColor colorWithRed:25.0 green:25.0 blue:25.0 alpha:1];
        [self.window.rootViewController.view addSubview:view];
    }
    
    //Dark Keyboard throughout the app
    [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];
    
    UITabBarController *tabController = (UITabBarController *)self.window.rootViewController;
    
    //tab1
    UIImage *selectedImage = [UIImage imageNamed:@"logotab"];
    UIImage *unselectedImage = [UIImage imageNamed:@"logotab"];
    UITabBar *tabBar = (UITabBar *)tabController.tabBar;
    UITabBarItem *item1 = [tabBar.items objectAtIndex:0];
    item1 = [item1 initWithTitle:@"Queue" image:unselectedImage selectedImage:selectedImage];
    
    //tab2
    selectedImage = [UIImage imageNamed:@"library-selected"];
    unselectedImage = [UIImage imageNamed:@"library"];
    UITabBarItem *item2 = [tabBar.items objectAtIndex:1];
    item2 = [item2 initWithTitle:@"Library" image:unselectedImage selectedImage:selectedImage];
    
    //tab3
    selectedImage = [UIImage imageNamed:@"favorites-selected"];
    unselectedImage = [UIImage imageNamed:@"favorites"];
    UITabBarItem *item3 = [tabBar.items objectAtIndex:2];
    item2 = [item3 initWithTitle:@"Favorites" image:unselectedImage selectedImage:selectedImage];
    
    //tab4
    selectedImage = [UIImage imageNamed:@"info-selected"];
    unselectedImage = [UIImage imageNamed:@"info"];
    UITabBarItem *item4 = [tabBar.items objectAtIndex:3];
    item4 = [item4 initWithTitle:@"Info" image:unselectedImage selectedImage:selectedImage];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
