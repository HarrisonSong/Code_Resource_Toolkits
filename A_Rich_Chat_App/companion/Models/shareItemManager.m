//
//  shareItemManager.m
//  companion
//
//  Created by qiyue song on 8/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "shareItemManager.h"
#import "Senior.h"
#import <Parse/Parse.h>

@implementation shareItemManager

+ (shareItemManager *)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static shareItemManager * _sharedObject = nil;
    
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
        if(_sharedObject){
            _sharedObject.tabBarItemBadgeNumber = @0;
            _sharedObject.isSystemAlertOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.silverline.companion.issystemalerton"];
            _sharedObject.needUpdateMessagePage = NO;
            _sharedObject.isSeniorDeleted = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.silverline.companion.isseniordeleted"];
            _sharedObject.isSeniorAdded = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.silverline.companion.issenioradded"];
        }
    });
    
    return _sharedObject;
}

- (NSMutableArray *)seniorList{
    if(_seniorList == nil) _seniorList = [NSMutableArray new];
    return _seniorList;
}

- (NSMutableArray *)fetchSeniorIdList{
    NSMutableArray * idList = [NSMutableArray new];
    for(Senior * object in self.seniorList){
        [idList addObject:object.objectId];
    }
    return idList;
}

- (void)setIsSystemAlertOn:(BOOL)isSystemAlertOn{
    _isSystemAlertOn = isSystemAlertOn;
    _needUpdateMessagePage = YES;
    [[NSUserDefaults standardUserDefaults] setBool:_isSystemAlertOn forKey:@"com.silverline.companion.issystemalerton"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIsSeniorDeleted:(BOOL)isSeniorDeleted{
    _isSeniorDeleted = isSeniorDeleted;
    [[NSUserDefaults standardUserDefaults] setBool:_isSeniorDeleted forKey:@"com.silverline.companion.isseniordeleted"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIsSeniorAdded:(BOOL)isSeniorAdded{
    _isSeniorAdded = isSeniorAdded;
    [[NSUserDefaults standardUserDefaults] setBool:_isSeniorAdded forKey:@"com.silverline.companion.issenioradded"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateUnreadMessageCount:(void(^)(BOOL succeed, NSError * error))completion{
    PFQuery * messageCountQuery = [PFQuery queryWithClassName:@"PushMessage"];
    [messageCountQuery whereKey:@"receiverId" equalTo:[PFUser currentUser].objectId];
    [messageCountQuery whereKey:@"isRead" equalTo:@NO];
    [messageCountQuery whereKey:@"senderId" containedIn:[self fetchSeniorIdList]];
    [messageCountQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if(!error){
            [shareItemManager sharedInstance].tabBarItemBadgeNumber = @(number);
            completion(YES, nil);
        }else{
            [shareItemManager sharedInstance].tabBarItemBadgeNumber = @0;
            NSLog(@"Failed to fetch number of unread message with error:%@",error);
            completion(NO, error);
        }
    }];
}

@end
