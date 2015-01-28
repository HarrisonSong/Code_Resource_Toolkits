//
//  AlertInbox.m
//  companion
//
//  Created by qiyue song on 10/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "AlertInbox.h"
#import <Parse/PFObject+Subclass.h>

@implementation AlertInbox 

@dynamic isPending;
@dynamic isRead;
@dynamic messageData;
@dynamic type;
@dynamic userId;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"AlertInbox";
}

@end
