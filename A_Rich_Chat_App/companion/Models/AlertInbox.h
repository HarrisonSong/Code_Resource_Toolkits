//
//  AlertInbox.h
//  companion
//
//  Created by qiyue song on 10/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import <Parse/Parse.h>

@interface AlertInbox : PFObject <PFSubclassing>

@property BOOL isPending;
@property BOOL isRead;
@property (nonatomic, strong) NSString * messageData;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) PFUser * userId;

+ (NSString *)parseClassName;

@end
