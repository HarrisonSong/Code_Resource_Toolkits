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
