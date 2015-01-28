//
//  SeniorListViewController.m
//  companion
//
//  Created by qiyue song on 12/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import "SeniorListViewController.h"
#import "AddSeniorViewController.h"
#import "InboxViewController.h"
#import "WellBeingViewController.h"
#import "Senior.h"
#import "SeniorCell.h"
#import "Message.h"
#import "shareItemManager.h"
#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface SeniorListViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *AddButtonItem;
- (IBAction)onAddUserButtonPressed:(id)sender;

@end

@implementation SeniorListViewController

- (NSMutableArray *)seniorsList{
    if(_seniorsList == nil) _seniorsList = [NSMutableArray array];
    return _seniorsList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:20.0]}];
    [self.AddButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:18.0]} forState:UIControlStateNormal];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadSeniorListWithCacheAndNetwork) forControlEvents:UIControlEventValueChanged];
    [self reloadSeniorListWithCacheAndNetwork];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveRemoteNotification:)
     name:@"UIApplicationDidReceiveRemoteAsNotification"
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveRemoteNotification:)
     name:@"UIApplicationDidReceiveRemoteCiNotification"
     object:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.seniorsList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 167;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] init];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SeniorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SeniorCell"];
    if (cell == nil) {
        // Load the top-level objects from the custom cell XIB.
        NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"SeniorCell" owner:self options:nil];
        cell = objects[0];
    }
    cell.seniorName.text = self.seniorsList[indexPath.row][@"name"];
    cell.seniorCheckedInTime.text = [NSDateFormatter localizedStringFromDate:self.seniorsList[indexPath.row][@"lastCheckedIn"] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    PFFile * avatarImageFile =  self.seniorsList[indexPath.row][@"profileImage"];
    [avatarImageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if(!error && data != nil){
            cell.seniorPhoto.image = [UIImage imageWithData:data];
        }else{
            NSLog(@"Failed to fetch senior avatar file.");
        }
    }];
    cell.TrackLocationButton.tag = indexPath.row;
    [cell.TrackLocationButton addTarget:self action:@selector(trackLocation:) forControlEvents:UIControlEventTouchDown];
    cell.InboxButton.tag = indexPath.row;
    [cell.InboxButton addTarget:self action:@selector(inbox:) forControlEvents:UIControlEventTouchDown];
    return cell;
}

#pragma mark - Table view delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    Senior * currentSenior = self.seniorsList[indexPath.row];
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    WellBeingViewController * WellBeingVC = [storyboard instantiateViewControllerWithIdentifier:@"WellBeing"];
    WellBeingVC.hidesBottomBarWhenPushed = YES;
    WellBeingVC.senior = currentSenior;
    [self.navigationController pushViewController:WellBeingVC animated:YES];
    NSLog(@"DEBUG: go to senior detailed page.");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
        PFQuery * seniorUserQuery = [PFQuery queryWithClassName:@"SeniorUsers"];
        [seniorUserQuery whereKey:@"user" equalTo:[PFUser currentUser]];
        [seniorUserQuery whereKey:@"senior" equalTo:self.seniorsList[indexPath.row]];
        SeniorListViewController __weak * weakSelf = self;
        [seniorUserQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(!error && objects.count > 0){
                [(PFObject *)objects[0] deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if(succeeded){
                        [weakSelf.seniorsList removeObjectAtIndex:indexPath.row];
                        [weakSelf.tableView beginUpdates];
                        [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                        [weakSelf.tableView endUpdates];
                        NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
                        [userDefault setObject:@YES forKey:@"com.silverline.companion.iscachedirty"];
                        [userDefault synchronize];
                        [weakSelf reloadSeniorListWithOnlyNetwork];
                    }else{
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to remove the member. Please try again.", @"remove senior error message")];
                        NSLog(@"%@", error);
                    }
                }];
            }else{
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to remove the member. Please try again.", @"remove senior error message")];
                NSLog(@"%@", error);
            }
        }];
    }
}

#pragma mark - helper method
- (void)reloadSeniorListWithCacheAndNetwork{
    [self reloadSeniorList:kPFCachePolicyCacheThenNetwork];
}

- (void)reloadSeniorListWithOnlyNetwork{
    [self reloadSeniorList:kPFCachePolicyNetworkOnly];
}

- (void)reloadSeniorList:(PFCachePolicy)policy{
    PFQuery * seniorUserQuery = [PFQuery queryWithClassName:@"SeniorUsers"];
    [seniorUserQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    [seniorUserQuery includeKey:@"senior"];
    seniorUserQuery.cachePolicy = policy;
    SeniorListViewController __weak * weakSelf = self;
    [seniorUserQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error){
            [weakSelf.seniorsList removeAllObjects];
            if(objects.count > 0){
                for(PFObject * object in objects){
                    [weakSelf.seniorsList addObject:[[Senior alloc] initByPFObject:object[@"senior"] withName:object[@"seniorFullName"] profileImage:object[@"seniorProfileImage"]]];
                }
            }
            
            /* Update the seniorList in shareInstance (for the usage of
             * message page and update application badge number)
             */
            [shareItemManager sharedInstance].seniorList = [NSMutableArray arrayWithArray:weakSelf.seniorsList];
            [[shareItemManager sharedInstance] updateUnreadMessageCount:^(BOOL succeed, NSError *error) {
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"updateTabBarBadgeNumber"
                 object:self
                 userInfo:nil];
            }];
            
            [weakSelf.tableView reloadData];
        }else{
            NSLog(@"No SeniorUser has been fetched with error: %@", error);
        }
        [weakSelf.refreshControl endRefreshing];
        [SVProgressHUD dismiss];
    }];
}

- (IBAction)onAddUserButtonPressed:(id)sender {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    AddSeniorViewController * addSeniorVC = [storyboard instantiateViewControllerWithIdentifier:@"AddSenior"];
    [self presentViewController:addSeniorVC animated:YES completion:nil];
}

- (void)trackLocation:(UIButton *)button{
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    Senior * currentSenior = self.seniorsList[button.tag];
    Message * newMessage = [Message object];
    newMessage.isPending = YES;
    newMessage.isRead = NO;
    newMessage.messageData = [NSString stringWithFormat:NSLocalizedString(@"%@ requests to track your location.", @"track location notification message"), [PFUser currentUser][@"name"]];
    newMessage.receiverId = currentSenior.objectId;
    newMessage.senderId = [PFUser currentUser].objectId;
    newMessage.type = @"tl";
    [newMessage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(succeeded){
            NSDictionary *data = @{@"alert":newMessage.messageData, @"badge":@"Increment", @"title":NSLocalizedString(@"Silverline Companion", @"application name"), @"t": @"tl", @"pid":newMessage.objectId, @"action":@"com.silverline.companion.UPDATE_STATUS"};
            PFPush *push = [[PFPush alloc] init];
            [push setData:data];
            PFQuery *pushQuery = [PFInstallation query];
            [pushQuery whereKey:@"owner" equalTo:currentSenior.objectId];
            [push setQuery:pushQuery];
            [push sendPushInBackground];
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Your request has been sent to the member.", @"track location successfully message")];
        }else{
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to send the request. Please try again.", @"track location error message")];
        }
    }];
}

- (void)inbox:(UIButton *)button{
    Senior * currentSenior = self.seniorsList[button.tag];
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    InboxViewController * inboxVC = [storyboard instantiateViewControllerWithIdentifier:@"Inbox"];
    inboxVC.hidesBottomBarWhenPushed = YES;
    inboxVC.senior = currentSenior;
    [self.navigationController pushViewController:inboxVC animated:YES];
}

- (void)didReceiveRemoteNotification:(NSNotification *)notif{
    if([notif.name isEqualToString:@"UIApplicationDidReceiveRemoteAsNotification"]){
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"com.silverline.companion.addseniorreload"];
    }
    [self reloadSeniorList:kPFCachePolicyNetworkOnly];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
