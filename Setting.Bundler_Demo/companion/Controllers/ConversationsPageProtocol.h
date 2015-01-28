//
//  ConversationsPageProtocol.h
//  companion
//
//  Created by qiyue song on 9/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol ConversationsPageProtocol <NSObject>

- (void)recoveryNotificationListener;
- (void)insertConversationContent:(id)message inboxSeniorId:(NSString *)seniorId;

@end