//
//  SettingViewController.m
//  companion
//
//  Created by qiyue song on 12/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import "SettingsViewController.h"
#import "WebViewController.h"
#import "shareItemManager.h"
#import "EnterpriseListViewController.h"
#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface SettingsViewController () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UILabel *AboutSilverlineLabel;
@property (weak, nonatomic) IBOutlet UILabel *PrivacyPolicyLabel;
@property (weak, nonatomic) IBOutlet UILabel *TermsOfServiceLabel;
@property (weak, nonatomic) IBOutlet UILabel *SystemAlertLabel;
@property (weak, nonatomic) IBOutlet UISwitch *SystemAlertSwitch;
@property (weak, nonatomic) IBOutlet UILabel *EnterPriseLabel;
@property (weak, nonatomic) IBOutlet UILabel *LogoutLabel;


@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:20.0]}];
    
    self.AboutSilverlineLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    self.PrivacyPolicyLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    self.TermsOfServiceLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    self.SystemAlertLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    self.EnterPriseLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    self.LogoutLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:17.0];
    
    self.tableView.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1.0];
    
    [self.SystemAlertSwitch addTarget:self action:@selector(onSystemAlertSwitchToggle:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0){
        return 3;
    }else{
        return 1;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if(section == 0){
        return [[UIView alloc] init];
    }else{
        UIView * headerView = [[UIView alloc] init];
        headerView.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1.0];
        return headerView;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView * footerView = [[UIView alloc] init];
    footerView.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1.0];
    return footerView;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 0){
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        WebViewController * WebVC = [storyboard instantiateViewControllerWithIdentifier:@"Web"];
        WebVC.hidesBottomBarWhenPushed = YES;
        switch (indexPath.row) {
            case 0:
            {
                WebVC.url = @"http://silverline.mobi/services";
                WebVC.navigationItem.title = @"About Silverline";
                break;
            }
            case 1:
            {
               
                WebVC.url = @"http://silverline.mobi/privacy-policy";
                WebVC.navigationItem.title = NSLocalizedString(@"Privacy Policy", @"Privacy Policy");
                break;
            }
            case 2:
            {
                WebVC.url = @"http://silverline.mobi/tos";
                WebVC.navigationItem.title = NSLocalizedString(@"Terms of Service", @"Terms of Service");;
                break;
            }
            default:
                break;
        }
        [self.navigationController pushViewController:WebVC animated:YES];
    }else if(indexPath.section == 2){
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        EnterpriseListViewController * enterpriseListVC = [storyboard instantiateViewControllerWithIdentifier:@"EnterpriseList"];
        [self.navigationController pushViewController:enterpriseListVC animated:YES];
    }
    else if(indexPath.section == 3){
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        UIActionSheet * logoutSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Confirm to logout?",@"logout alert message") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"cancel") destructiveButtonTitle:NSLocalizedString(@"Log Out", @"log out string") otherButtonTitles:nil];
        [logoutSheet showInView:self.view];
    }
}

#pragma mark - UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 0){
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == 0){
        [PFUser logOut];
        [PFQuery clearAllCachedResults];
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
        UIWindow * window = [UIApplication sharedApplication].windows.firstObject;
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UINavigationController * loginNaviVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginNavi"];
        [SVProgressHUD dismiss];
        [window setRootViewController:loginNaviVC];
    }
}

#pragma mark - Helper Methods
- (void)onSystemAlertSwitchToggle:(UISwitch *)sender{
    [shareItemManager sharedInstance].isSystemAlertOn = sender.isOn;
}

@end
