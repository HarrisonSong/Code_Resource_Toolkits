//
//  Message.h
//  companion
//
//  Created by qiyue song on 7/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import <Parse/Parse.h>

@interface Message : PFObject <PFSubclassing>

@property (nonatomic, strong) NSString * address;
@property BOOL isPending;
@property BOOL isRead;
@property (nonatomic, strong) PFGeoPoint * location;
@property (nonatomic, strong) NSString * messageData;
@property (nonatomic, strong) PFFile * messageImg;
@property (nonatomic, strong) PFFile * messageImgThumb;
@property (nonatomic, strong) NSString * receiverId;
@property (nonatomic, strong) NSString * senderId;
@property (nonatomic, strong) NSString * type;
@property (nonatomic, strong) NSString * videoUrl;

+ (NSString *)parseClassName;

@end
