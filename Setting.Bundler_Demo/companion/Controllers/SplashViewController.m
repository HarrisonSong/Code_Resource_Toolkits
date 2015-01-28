//
//  SplashViewController.m
//  companion
//
//  Created by qiyue song on 5/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import "SplashViewController.h"
#import "AddSeniorViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import <Parse/Parse.h>
#import <FacebookSDK/FacebookSDK.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>

@interface SplashViewController ()

@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
    // Do any additional setup after loading the view.
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([PFUser currentUser] && // Check if user is cached
        [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) { // Check if user is linked to Facebook
        PFInstallation * currentInstallation = [PFInstallation currentInstallation];
        currentInstallation[@"owner"] = [PFUser currentUser].objectId;
        [currentInstallation saveInBackground];
        
        UIWindow * window = [UIApplication sharedApplication].windows.firstObject;
        UITabBarController * TabbarVC = [storyboard instantiateViewControllerWithIdentifier:@"Tabs"];
        UITabBar * currentTabBar = TabbarVC.tabBar;
        
        UITabBarItem * listTabBarItem = [[currentTabBar items] objectAtIndex:0];
        UIImage * listIcon = [UIImage imageNamed:@"ListIconSelected"];
        [listTabBarItem setSelectedImage:listIcon];
        UITabBarItem * messageTabBarItem = [[currentTabBar items] objectAtIndex:1];
        UIImage * messageIcon = [UIImage imageNamed:@"MessageIconSelected"];
        [messageTabBarItem setSelectedImage:messageIcon];
        
        UITabBarItem * settingTabBarItem = [[currentTabBar items] objectAtIndex:2];
        UIImage * settingIcon = [UIImage imageNamed:@"SettingIconSelected"];
        [settingTabBarItem setSelectedImage:settingIcon];
        
        window.rootViewController = TabbarVC;
    }else{
        UINavigationController * LoginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginNavi"];
        LoginVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:LoginVC animated:YES completion:nil];
    }
}

@end