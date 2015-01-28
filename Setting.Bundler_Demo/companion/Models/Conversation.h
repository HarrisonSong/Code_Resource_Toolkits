//
//  Conversation.h
//  companion
//
//  Created by qiyue song on 8/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Conversation : NSObject

@property (nonatomic, assign) int badgeNumber;
@property (nonatomic, strong) NSString * lastContent;
@property (nonatomic, strong) NSDate * lastDate;
@property (nonatomic, strong) NSString * seniorId;
@property (nonatomic, assign) BOOL hasUnreadMessage;

@end
