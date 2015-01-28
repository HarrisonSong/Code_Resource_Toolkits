//
//  MessageViewController.m
//  companion
//
//  Created by qiyue song on 6/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import "MessagesViewController.h"
#import "InboxViewController.h"
#import "AlertsViewController.h"
#import "MessageCell.h"
#import "Senior.h"
#import "Message.h"
#import "Conversation.h"
#import "AlertInbox.h"
#import "shareItemManager.h"
#import <Parse/Parse.h>
#import <PromiseKit/PromiseKit.h>
#import <JSBadgeView/JSBadgeView.h>

@interface MessagesViewController ()

@property (nonatomic, strong) NSMutableArray * conversationsList;
@property (nonatomic, strong) NSMutableDictionary * seniorsDict;

@end

@implementation MessagesViewController

- (NSMutableArray *)conversationsList{
    if(_conversationsList == nil) _conversationsList = [NSMutableArray array];
    return _conversationsList;
}

- (NSMutableDictionary *)seniorsDict{
    if(_seniorsDict == nil) _seniorsDict = [NSMutableDictionary dictionary];
    return _seniorsDict;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:20.0]}];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadConversationsList) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl beginRefreshing];
    [self reloadConversationsList];
        
    
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
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveRemoteNotification:)
     name:@"UIApplicationDidReceiveRemoteMrNotification"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveInboxNotification:)
     name:@"updateConversation"
     object:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    if([shareItemManager sharedInstance].isSeniorDeleted ){
        [shareItemManager sharedInstance].isSeniorDeleted = NO;
        [self.conversationsList removeAllObjects];
        [self.tableView reloadData];
        [self.refreshControl beginRefreshing];
        [self reloadConversationsList];
    }
    if([shareItemManager sharedInstance].isSeniorAdded || [shareItemManager sharedInstance].needUpdateMessagePage){
        [shareItemManager sharedInstance].isSeniorAdded = NO;
        [shareItemManager sharedInstance].needUpdateMessagePage = NO;
        [self.refreshControl beginRefreshing];
        [self reloadConversationsList];
    }
    [super viewDidAppear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.conversationsList.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] init];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell * cell = [tableView dequeueReusableCellWithIdentifier:@"MessageCell"];
    Conversation * currentConversation = self.conversationsList[indexPath.row];
    if (cell == nil) {
        // Load the top-level objects from the custom cell XIB.
        NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"MessageCell" owner:self options:nil];
        cell = objects[0];
    }
    cell.messageContent.text = currentConversation.lastContent;
    cell.messageDate.text = [NSDateFormatter localizedStringFromDate:currentConversation.lastDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    if([currentConversation.seniorId isEqualToString:[PFUser currentUser].objectId]){
        cell.messageUsername.text = NSLocalizedString(@"System Alert", @"System Alert Conversation title");
        cell.messagePhoto.image = [UIImage imageNamed:@"AlertImage"];
    }else{
        Senior * currentSenior = self.seniorsDict[currentConversation.seniorId];
        cell.messageUsername.text = currentSenior.name;
        PFFile * photo = currentSenior.profileImage;
        [photo getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if(!error && data){
                cell.messagePhoto.image = [UIImage imageWithData:data];
                if(currentConversation.hasUnreadMessage){
                    JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:cell.messagePhoto alignment:JSBadgeViewAlignmentTopRight];
                    badgeView.badgeText = [NSString stringWithFormat:@"%d", currentConversation.badgeNumber];
                }
            }else{
                if(error){
                    NSLog(@"Failed to get the message photo with error: %@",error);
                }
            }
        }];
    }
    if(currentConversation.hasUnreadMessage){
        cell.backgroundColor = [UIColor colorWithRed:203.0/255.0 green:210.0/255.0 blue:234.0/255.0 alpha:1];
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 97.0;
}

# pragma mark - table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView cellForRowAtIndexPath:indexPath].backgroundColor = [UIColor whiteColor];
    if(indexPath.row < self.seniorsDict.allKeys.count){
        Conversation * currentConversation = self.conversationsList[indexPath.row];
        currentConversation.hasUnreadMessage = NO;
        currentConversation.badgeNumber = 0;
        if(((MessageCell *)[tableView cellForRowAtIndexPath:indexPath]).messagePhoto.subviews.count > 0){
            [((MessageCell *)[tableView cellForRowAtIndexPath:indexPath]).messagePhoto.subviews[0] removeFromSuperview];
        }
        Senior * currentSenior = self.seniorsDict[currentConversation.seniorId];
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        InboxViewController * inboxVC = [storyboard instantiateViewControllerWithIdentifier:@"Inbox"];
        inboxVC.hidesBottomBarWhenPushed = YES;
        inboxVC.senior = currentSenior;
        
        [[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:@"UIApplicationDidReceiveRemoteAsNotification"
         object:nil];
        [[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:@"UIApplicationDidReceiveRemoteCiNotification"
         object:nil];
        [[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:@"UIApplicationDidReceiveRemoteMrNotification"
         object:nil];
        [[NSNotificationCenter defaultCenter]
         removeObserver:self
         name:@"updateConversation"
         object:nil];
        
        inboxVC.delegate = self;
        [self.navigationController pushViewController:inboxVC animated:YES];
    }else{
        Conversation * currentConversation = self.conversationsList[indexPath.row];
        currentConversation.hasUnreadMessage = NO;
        currentConversation.badgeNumber = 0;
        if(((MessageCell *)[tableView cellForRowAtIndexPath:indexPath]).messagePhoto.subviews.count > 0){
            [((MessageCell *)[tableView cellForRowAtIndexPath:indexPath]).messagePhoto.subviews[0] removeFromSuperview];
        }
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AlertsViewController * AlertVC = [storyboard instantiateViewControllerWithIdentifier:@"Alerts"];
        AlertVC.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:AlertVC animated:YES];
    }
}

# pragma mark - helper methods
- (void)reloadConversationsList{
    NSLog(@"cached object %@", [shareItemManager sharedInstance].seniorList);
    [self.seniorsDict removeAllObjects];
    [self.conversationsList removeAllObjects];
    NSMutableArray * promisesList = [NSMutableArray array];
    if([shareItemManager sharedInstance].seniorList.count > 0){
        for(PFObject * newSenior in [shareItemManager sharedInstance].seniorList){
            self.seniorsDict[newSenior.objectId] = newSenior;
            Conversation * newConversation = [[Conversation alloc] init];
            newConversation.seniorId = newSenior.objectId;
            PMKPromise * countPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
                PFQuery * messageQuery = [Message query];
                [messageQuery whereKey:@"receiverId" equalTo:[PFUser currentUser].objectId];
                [messageQuery whereKey:@"senderId" equalTo:newConversation.seniorId];
                [messageQuery whereKey:@"isRead" equalTo:@NO];
                [messageQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    if(!error){
                        newConversation.badgeNumber = number;
                        if(number == 0){
                            newConversation.hasUnreadMessage = NO;
                        }else{
                            newConversation.hasUnreadMessage = YES;
                        }
                        fulfill(@"successfully");
                    }else{
                        newConversation.badgeNumber = 0;
                        newConversation.hasUnreadMessage = NO;
                        reject(error);
                    }
                }];
            }];
            PMKPromise * lastMessagePromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
                PFQuery * messageQuery1 = [Message query];
                [messageQuery1 whereKey:@"receiverId" equalTo:[PFUser currentUser].objectId];
                [messageQuery1 whereKey:@"senderId" equalTo:newConversation.seniorId];
                PFQuery * messageQuery2 = [Message query];
                [messageQuery2 whereKey:@"senderId" equalTo:[PFUser currentUser].objectId];
                [messageQuery2 whereKey:@"receiverId" equalTo:newConversation.seniorId];
                PFQuery * messagesQuery = [PFQuery orQueryWithSubqueries:@[messageQuery1, messageQuery2]];
                [messagesQuery orderByDescending:@"createdAt"];
                [messagesQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if(!error){
                        if([((Message *)object).messageData isEqualToString:@""]){
                            if ([((Message *)object).type isEqualToString:@"up"]) {
                                newConversation.lastContent = NSLocalizedString(@"You sent a photo.", @"the messageContent when companion sends a photo with empty message");
                            } else if([((Message *)object).type isEqualToString:@"vd"]){
                                newConversation.lastContent = NSLocalizedString(@"You sent a video.", @"the messageContent when companion sends a video with empty message");
                            }
                        }else{
                            newConversation.lastContent = ((Message *)object).messageData;
                            newConversation.lastDate = object.createdAt;
                        }
                        newConversation.lastDate = object.createdAt;
                        fulfill(@"successfully");
                    }else{
                        reject(error);
                    }
                }];
            }];
            [promisesList addObject:countPromise];
            [promisesList addObject:lastMessagePromise];
            [self.conversationsList addObject:newConversation];
        }
    }
    
    if([shareItemManager sharedInstance].isSystemAlertOn){
        // Add System alert Conversation
        Conversation * newConversation = [[Conversation alloc] init];
        newConversation.seniorId = [PFUser currentUser].objectId;
        PMKPromise * countPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
            PFQuery * messageQuery = [AlertInbox query];
            [messageQuery whereKey:@"userId" equalTo:[PFUser currentUser]];
            [messageQuery whereKey:@"type" equalTo:@"sys"];
            [messageQuery whereKey:@"isRead" equalTo:@NO];
            [messageQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                if(!error){
                    newConversation.badgeNumber = number;
                    if(number == 0){
                        newConversation.hasUnreadMessage = NO;
                    }else{
                        newConversation.hasUnreadMessage = YES;
                    }
                    fulfill(@"successfully");
                }else{
                    newConversation.badgeNumber = 0;
                    newConversation.hasUnreadMessage = NO;
                    reject(error);
                }
            }];
        }];
        PMKPromise * lastAlertPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
            PFQuery * alertQuery = [AlertInbox query];
            [alertQuery whereKey:@"userId" equalTo:[PFUser currentUser]];
            [alertQuery whereKey:@"type" equalTo:@"sys"];
            [alertQuery getFirstObjectInBackgroundWithBlock:^(PFObject * object, NSError *error) {
                if(!error){
                    newConversation.lastContent = ((AlertInbox *)object).messageData;
                    newConversation.lastDate = object.createdAt;
                    fulfill(@"successfully");
                }else{
                    newConversation.lastContent = NSLocalizedString(@"No more new alert.", @"no more new message");
                    newConversation.lastDate = [NSDate new];
                    reject(error);
                }
            }];
        }];
        [promisesList addObject:countPromise];
        [promisesList addObject:lastAlertPromise];
        [self.conversationsList addObject:newConversation];
    }

    // Process the promises
    [PMKPromise when:promisesList].then(^(NSArray *results){
    }).catch(^(NSError * error){
        NSLog(@"%@",error);
    }).finally(^{
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    });
    [[shareItemManager sharedInstance] updateUnreadMessageCount:^(BOOL succeed, NSError *error) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateTabBarBadgeNumber"
         object:self
         userInfo:nil];
    }];
}

#pragma mark - ConversationsPageProtocol
- (void)recoveryNotificationListener{
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
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveRemoteNotification:)
     name:@"UIApplicationDidReceiveRemoteMrNotification"
     object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveInboxNotification:)
     name:@"updateConversation"
     object:nil];
}

- (void)insertConversationContent:(id)message inboxSeniorId:(NSString *)inboxSeniorId{
    NSString * seniorId = @"";
    if([((Message *)message).senderId isEqualToString:[PFUser currentUser].objectId]){
        seniorId = ((Message *)message).receiverId;
    }else{
        seniorId = ((Message *)message).senderId;
    }
    for(int i = 0; i < self.conversationsList.count; i++){
        Conversation * currentConversation = self.conversationsList[i];
        if([currentConversation.seniorId isEqualToString:seniorId]){
            if(![inboxSeniorId isEqualToString:seniorId]){
                currentConversation.badgeNumber = currentConversation.badgeNumber + 1;
                currentConversation.hasUnreadMessage = YES;
            }else{
                currentConversation.badgeNumber = 0;
                currentConversation.hasUnreadMessage = NO;
            }
            currentConversation.lastContent = ((Message *)message).messageData;
            currentConversation.lastDate = ((Message *)message).createdAt;
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)didReceiveRemoteNotification:(NSNotification *)notif{
    NSString * objectId = notif.userInfo[@"pid"];
    PFQuery * messageQuery = [Message query];
    MessagesViewController __weak * weakSelf = self;
    [messageQuery getObjectInBackgroundWithId:objectId block:^(PFObject * object, NSError *error) {
        if(!error && object){
            NSString * senderId = ((Message *)object).senderId;
            [weakSelf updateConversation:senderId];
        }
    }];
    [[shareItemManager sharedInstance] updateUnreadMessageCount:^(BOOL succeed, NSError *error) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateTabBarBadgeNumber"
         object:self
         userInfo:nil];
    }];
}

- (void)didReceiveInboxNotification:(NSNotification *)notif{
    [self updateConversation:notif.userInfo[@"seniorId"]];
    [[shareItemManager sharedInstance] updateUnreadMessageCount:^(BOOL succeed, NSError *error) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateTabBarBadgeNumber"
         object:self
         userInfo:nil];
    }];
}

- (void)updateConversation:(NSString *)seniorId{
    MessagesViewController __weak * weakSelf = self;
    for(int i = 0; i < self.conversationsList.count; i++){
        Conversation * currentConversation = self.conversationsList[i];
        if([currentConversation.seniorId isEqualToString:seniorId]){
            PMKPromise * countPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
                PFQuery * messageQuery = [PFQuery queryWithClassName:@"PushMessage"];
                [messageQuery whereKey:@"receiverId" equalTo:[PFUser currentUser].objectId];
                [messageQuery whereKey:@"senderId" equalTo:currentConversation.seniorId];
                [messageQuery whereKey:@"isRead" equalTo:@NO];
                [messageQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    if(!error){
                        currentConversation.badgeNumber = number;
                        if(number == 0){
                            currentConversation.hasUnreadMessage = NO;
                        }else{
                            currentConversation.hasUnreadMessage = YES;
                        }
                        fulfill(@"successfully");
                    }else{
                        currentConversation.badgeNumber = 0;
                        currentConversation.hasUnreadMessage = NO;
                        reject(error);
                    }
                }];
            }];
            PMKPromise * lastMessagePromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
                PFQuery * messageQuery1 = [PFQuery queryWithClassName:@"PushMessage"];
                [messageQuery1 whereKey:@"receiverId" equalTo:[PFUser currentUser].objectId];
                [messageQuery1 whereKey:@"senderId" equalTo:currentConversation.seniorId];
                PFQuery * messageQuery2 = [PFQuery queryWithClassName:@"PushMessage"];
                [messageQuery2 whereKey:@"senderId" equalTo:[PFUser currentUser].objectId];
                [messageQuery2 whereKey:@"receiverId" equalTo:currentConversation.seniorId];
                PFQuery * messagesQuery = [PFQuery orQueryWithSubqueries:@[messageQuery1, messageQuery2]];
                [messagesQuery orderByDescending:@"createdAt"];
                [messagesQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if(!error){
                        currentConversation.lastContent = ((Message *)object).messageData;
                        currentConversation.lastDate = object.createdAt;
                        fulfill(@"successfully");
                    }else{
                        reject(error);
                    }
                }];
            }];
            [PMKPromise when:@[countPromise, lastMessagePromise]].then(^(NSArray *results){
            }).catch(^(NSError * error){
                NSLog(@"%@",error);
            }).finally(^{
                [weakSelf.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            });
            break;
        }
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
