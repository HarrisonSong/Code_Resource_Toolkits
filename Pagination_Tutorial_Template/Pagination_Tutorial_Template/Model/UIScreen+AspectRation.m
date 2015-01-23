//
//  UIScreen+AspectRation.m
//  Pagination_Tutorial_Template
//
//  Created by qiyue song on 23/1/15.
//  Copyright (c) 2015 qiyuesong. All rights reserved.
//

#import "UIScreen+AspectRation.h"

@implementation UIScreen (AspectRation)

- (UIScreenAspectRatio)aspectRatio {
    
    float ratio = self.bounds.size.width / self.bounds.size.height;
    
    if (ratio == 320.0f/480.0f || ratio == 480.0f/320.0f || ratio == 1024.0f/768.0f || ratio == 768.0f/1024.0f) return UIScreenAspectRatio3by2;
    else if (ratio == 320.0f/568.0f || ratio == 568.0f/320.0f || ratio == 375.0f/667.0f || ratio == 667.0f/375.0f || ratio == 736.0f/414.0f || ratio == 414.0f/736.0f) return UIScreenAspectRatio16by9;
    
    return UIScreenAspectRatioUnknown;
}


@end