//
//  MessageViewController.h
//  companion
//
//  Created by qiyue song on 6/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConversationsPageProtocol.h"

@interface MessagesViewController : UITableViewController <ConversationsPageProtocol>

- (void)reloadConversationsList;

@end
