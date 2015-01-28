//
//  LocationViewController.h
//  companion
//
//  Created by qiyue song on 28/11/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface LocationViewController : UIViewController

@property (nonatomic) PFGeoPoint * location;

@end
