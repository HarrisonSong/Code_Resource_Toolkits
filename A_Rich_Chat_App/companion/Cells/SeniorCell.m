//
//  SeniorCell.m
//  Silverline Companion
//
//  Created by qiyue song on 6/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import "SeniorCell.h"
@interface SeniorCell ()

@property (weak, nonatomic) IBOutlet UILabel *lastCheckTimeLabel;

@end

@implementation SeniorCell

- (void)awakeFromNib {
    // Initialization code
    self.seniorName.font = [UIFont fontWithName:@"OpenSans-Bold" size:26.0];
    self.seniorCheckedInTime.font = [UIFont fontWithName:@"OpenSans-Light" size:17.0];
    self.lastCheckTimeLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
