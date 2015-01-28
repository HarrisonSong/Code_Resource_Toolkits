//
//  SeniorListViewController.h
//  companion
//
//  Created by qiyue song on 12/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SeniorListViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray * seniorsList;

- (void)reloadSeniorListWithCacheAndNetwork;
- (void)reloadSeniorListWithOnlyNetwork;

@end
