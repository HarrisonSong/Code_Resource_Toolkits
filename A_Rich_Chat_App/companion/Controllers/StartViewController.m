//
//  StartViewController.m
//  companion
//
//  Created by qiyue song on 2/3/15.
//  Copyright (c) 2015 silverline. All rights reserved.
//

#import "StartViewController.h"
#import "shareItemManager.h"

#import <SVProgressHUD/SVProgressHUD.h>

@interface StartViewController ()

@property (weak, nonatomic) IBOutlet UILabel *WelcomeToLabel;
@property (weak, nonatomic) IBOutlet UILabel *AppNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *SuccessLabel;
@property (weak, nonatomic) IBOutlet UILabel *noticeFirstLineLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *noticeLastLineLabel;
@property (weak, nonatomic) IBOutlet UIButton *StartButton;

- (IBAction)onStartButtonPressed:(UIButton *)sender;
@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.emailLabel.text = self.email;
    
    self.WelcomeToLabel.font = [UIFont fontWithName:@"OpenSans" size:20.0];
    self.AppNameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:26.0];
    self.SuccessLabel.font = [UIFont fontWithName:@"OpenSans" size:26.0];
    self.noticeFirstLineLabel.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.noticeLastLineLabel.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.emailLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:18.0];
    self.StartButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:18.0];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 4;
}

- (IBAction)onStartButtonPressed:(UIButton *)sender {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [self presentNextPageAfterLogin:YES];
}

- (void)presentNextPageAfterLogin:(BOOL)animated {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
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
    [[shareItemManager sharedInstance] updateUnreadMessageCount:^(BOOL succeed, NSError *error) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateTabBarBadgeNumber"
         object:self
         userInfo:nil];
    }];
}

@end
