//
//  InboxViewController.h
//  companion
//
//  Created by qiyue song on 24/11/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConversationsPageProtocol.h"
#import "Senior.h"

@interface InboxViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *TableView;
@property (nonatomic, strong) Senior * senior;
@property (nonatomic, strong) NSMutableArray * messagesList;
@property (nonatomic, strong) id<ConversationsPageProtocol> delegate;

@end
