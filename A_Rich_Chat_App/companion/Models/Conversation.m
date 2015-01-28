//
//  Conversation.m
//  companion
//
//  Created by qiyue song on 8/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "Conversation.h"

@implementation Conversation

-(instancetype)init{
    self =  [super init];
    if(self){
        self.badgeNumber = 0;
        self.lastContent = @"";
        self.lastDate = [NSDate date];
        self.seniorId = @"";
        self.hasUnreadMessage = NO;
    }
    return self;
}

@end
