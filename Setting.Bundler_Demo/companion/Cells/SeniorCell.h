//
//  SeniorCell.h
//  Silverline Companion
//
//  Created by qiyue song on 6/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SeniorCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *seniorPhoto;
@property (weak, nonatomic) IBOutlet UILabel *seniorName;
@property (weak, nonatomic) IBOutlet UILabel *seniorCheckedInTime;
@property (weak, nonatomic) IBOutlet UIButton *TrackLocationButton;
@property (weak, nonatomic) IBOutlet UIButton *InboxButton;

@end
