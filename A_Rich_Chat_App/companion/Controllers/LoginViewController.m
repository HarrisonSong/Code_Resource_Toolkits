//
//  LoginViewController.m
//  companion
//
//  Created by qiyue song on 30/10/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import "LoginViewController.h"
#import "WebViewController.h"
#import "shareItemManager.h"
#import "EmailLoginViewController.h"

#import <Parse/Parse.h>
#import <FacebookSDK/FacebookSDK.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UILabel *WelcomeToLabel;
@property (weak, nonatomic) IBOutlet UILabel *AppNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *BottomLabel;
@property (weak, nonatomic) IBOutlet UIButton *TermsButton;
@property (weak, nonatomic) IBOutlet UIButton *PolicyButton;
@property (weak, nonatomic) IBOutlet UIButton *LoginButton;
@property (weak, nonatomic) IBOutlet UIButton *EmailLoginButton;

- (IBAction)onTermsButtonPressed:(UIButton *)sender;
- (IBAction)onPolicyButtonPressed:(UIButton *)sender;
- (IBAction)FacebookLoginButtonPressed:(UIButton *)sender;
- (IBAction)onEmailLoginButtonPressed:(UIButton *)sender;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.WelcomeToLabel.font = [UIFont fontWithName:@"OpenSans" size:20.0];
    self.AppNameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:26.0];
    self.BottomLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:14.0];
    self.TermsButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:14.0];
    self.PolicyButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:14.0];
    if(![[NSLocale preferredLanguages][0] isEqualToString:@"ms"]){
        self.LoginButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:24.0];
    }else{
        self.LoginButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    }
    self.EmailLoginButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:24.0];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.navigationBarHidden = YES;
}

- (IBAction)FacebookLoginButtonPressed:(UIButton *)sender {
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"public_profile", @"user_about_me", @"user_relationships", @"user_birthday", @"user_location"];      
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            NSString *errorMessage = nil;
            if (!error) {
                NSLog(@"Uh oh. The user cancelled the Facebook login.");
                errorMessage = @"Uh oh. The user cancelled the Facebook login.";
            } else {
                NSLog(@"Uh oh. An error occurred: %@", error);
                errorMessage = [error localizedDescription];
            }
            [SVProgressHUD showErrorWithStatus:errorMessage];
        } else {
            PFInstallation * currentInstallation = [PFInstallation currentInstallation];
            currentInstallation[@"owner"] = [PFUser currentUser].objectId;
            [currentInstallation saveInBackground];
            FBRequest *request = [FBRequest requestForMe];
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    // result is a dictionary with the user's Facebook data
                    NSDictionary *userData = (NSDictionary *)result;
                    NSString * email = userData[@"email"];
                    NSString *facebookID = userData[@"id"];
                    NSString *firstName = userData[@"first_name"];
                    NSString *gender = userData[@"gender"];
                    NSString *lastName = userData[@"last_name"];
                    NSString *link = userData[@"link"];
                    NSString *locale = userData[@"locale"];
                    NSString *name = userData[@"name"];
                    NSString *type = @"Companion";
                    
                    user[@"email"] = email;
                    user.username = email;
                    user[@"facebookId"] = facebookID;
                    user[@"firstName"] = firstName;
                    user[@"gender"] = gender;
                    user[@"lastName"] = lastName;
                    user[@"link"] = link;
                    user[@"locale"] = locale;
                    user[@"name"] = name;
                    user[@"type"] = type;
                    user[@"profileImage"] = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID];
                    [user saveInBackground];
                }else{
                    NSLog(@"User information saved unsuccessfully!");
                }
                [self presentNextPageAfterLogin:YES];
            }];
        }
    }];
}

- (IBAction)onEmailLoginButtonPressed:(UIButton *)sender {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController * emailLoginVC = [storyboard instantiateViewControllerWithIdentifier:@"EmailLoginNavi"];
    [self presentViewController:emailLoginVC animated:YES completion:nil];
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

- (IBAction)onTermsButtonPressed:(UIButton *)sender {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    WebViewController * WebVC = [storyboard instantiateViewControllerWithIdentifier:@"Web"];
    WebVC.url = @"http://silverline.mobi/tos";
    WebVC.navigationItem.title = NSLocalizedString(@"Terms of Service", @"Terms of Service");
    [self.navigationController pushViewController:WebVC animated:YES];
}

- (IBAction)onPolicyButtonPressed:(UIButton *)sender {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    WebViewController * WebVC = [storyboard instantiateViewControllerWithIdentifier:@"Web"];
    WebVC.url = @"http://silverline.mobi/privacy-policy";
    WebVC.navigationItem.title = NSLocalizedString(@"Privacy Policy", @"Privacy Policy");
    [self.navigationController pushViewController:WebVC animated:YES];
}

@end
