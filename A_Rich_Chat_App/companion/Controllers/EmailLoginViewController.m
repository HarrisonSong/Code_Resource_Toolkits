//
//  EmailLoginViewController.m
//  companion
//
//  Created by qiyue song on 2/3/15.
//  Copyright (c) 2015 silverline. All rights reserved.
//

#import "EmailLoginViewController.h"
#import "shareItemManager.h"
#import "RegisterViewController.h"

#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface EmailLoginViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *EmailField;
@property (weak, nonatomic) IBOutlet UITextField *PasswordField;
@property (weak, nonatomic) IBOutlet UIButton *EmailLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *RegisterButton;
@property (weak, nonatomic) IBOutlet UILabel *WelcomeToLabel;
@property (weak, nonatomic) IBOutlet UILabel *AppNameLabel;

- (IBAction)onCancelButtonPressed:(UIButton *)sender;
- (IBAction)onEmailLoginButtonPressed:(UIButton *)sender;
- (IBAction)onRegisterButtonPressed:(UIButton *)sender;

@end

@implementation EmailLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:20.0]}];
    self.WelcomeToLabel.font = [UIFont fontWithName:@"OpenSans" size:20.0];
    self.AppNameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:26.0];
    self.EmailField.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.PasswordField.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.EmailLoginButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:22.0];
    self.RegisterButton.titleLabel.font =
    [UIFont fontWithName:@"OpenSans-Bold" size:17.0];
    
    self.EmailField.delegate = self;
    self.PasswordField.delegate = self;
    self.EmailLoginButton.enabled = NO;
    self.EmailLoginButton.alpha = 0.6;
    
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

#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if(textField.text.length - range.length + string.length > 0){
        if(([textField isEqual:self.EmailField] && self.PasswordField.text.length == 0) || ([textField isEqual:self.PasswordField] && self.EmailField.text.length == 0)){
            self.EmailLoginButton.enabled = NO;
            self.EmailLoginButton.alpha = 0.6;
        }else{
            self.EmailLoginButton.enabled = YES;
            self.EmailLoginButton.alpha = 1;
        }
    }else{
        self.EmailLoginButton.enabled = NO;
        self.EmailLoginButton.alpha = 0.6;
    }
    return YES;
}

- (IBAction)onCancelButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onEmailLoginButtonPressed:(UIButton *)sender {
    [self.view endEditing:YES];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    EmailLoginViewController * __weak weakSelf = self;
    [PFUser logInWithUsernameInBackground:self.EmailField.text password:self.PasswordField.text block:^(PFUser *user, NSError *error) {
        if(!error && user){
            // Go to senior list page
            PFInstallation * currentInstallation = [PFInstallation currentInstallation];
            currentInstallation[@"owner"] = [PFUser currentUser].objectId;
            [currentInstallation saveInBackground];
            
            [weakSelf presentNextPageAfterLogin:YES];
        }else{
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Email or password is incorrect. Please try again.", @"login error message")];
        }
    }];
    
}

- (IBAction)onRegisterButtonPressed:(UIButton *)sender {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    RegisterViewController * registerVC = [storyboard instantiateViewControllerWithIdentifier:@"Register"];
    [self.navigationController pushViewController:registerVC animated:YES];
}

#pragma mark - helper methods
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

- (void)dismissKeyboard{
    [self.view endEditing:YES];
}

@end
