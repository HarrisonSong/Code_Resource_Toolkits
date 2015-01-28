//
//  Message.m
//  companion
//
//  Created by qiyue song on 7/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import "Message.h"
#import <Parse/PFObject+Subclass.h>

@implementation Message

@dynamic address;
@dynamic isPending;
@dynamic isRead;
@dynamic location;
@dynamic messageData;
@dynamic messageImg;
@dynamic messageImgThumb;
@dynamic receiverId;
@dynamic senderId;
@dynamic type;
@dynamic videoUrl;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"PushMessage";
}

@end
