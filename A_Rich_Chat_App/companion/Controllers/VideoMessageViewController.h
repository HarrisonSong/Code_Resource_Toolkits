//
//  VideoMessageViewController.h
//  companion
//
//  Created by qiyue song on 14/1/15.
//  Copyright (c) 2015 silverline. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Senior;

@interface VideoMessageViewController : UITableViewController

@property (nonatomic, strong) NSURL * videoUrl;
@property (nonatomic, strong) Senior * senior;

@end
