//
//  TourPageViewController.h
//  Pagination_Tutorial_Template
//
//  Created by qiyue song on 23/1/15.
//  Copyright (c) 2015 qiyuesong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TourPageViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIImageView *TourImage;
@property NSUInteger pageIndex;
@property NSString * imageFile;
@end
