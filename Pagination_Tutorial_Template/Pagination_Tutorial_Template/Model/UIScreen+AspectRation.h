//
//  UIScreen+AspectRation.h
//  Pagination_Tutorial_Template
//
//  Created by qiyue song on 23/1/15.
//  Copyright (c) 2015 qiyuesong. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
    UIScreenAspectRatioUnknown,
    UIScreenAspectRatio3by2,
    UIScreenAspectRatio16by9
} UIScreenAspectRatio;


@interface UIScreen (AspectRation)

@property (nonatomic, readonly) UIScreenAspectRatio aspectRatio;


@end
