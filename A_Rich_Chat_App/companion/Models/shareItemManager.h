//
//  shareItemManager.h
//  companion
//
//  Created by qiyue song on 8/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface shareItemManager : NSObject

@property (nonatomic, assign) NSNumber * tabBarItemBadgeNumber;
@property (nonatomic, strong) NSMutableArray * seniorList;

+ (shareItemManager *)sharedInstance;

- (void)updateUnreadMessageCount:(void(^)(BOOL succeed, NSError * error))completion;

@end
