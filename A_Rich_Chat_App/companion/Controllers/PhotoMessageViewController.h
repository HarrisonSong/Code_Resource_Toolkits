//
//  PhotoMessageViewController.h
//  companion
//
//  Created by qiyue song on 25/11/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Senior;

@interface PhotoMessageViewController : UITableViewController

@property (nonatomic, strong) UIImage * photo;
@property (nonatomic, strong) Senior * senior;

@end
