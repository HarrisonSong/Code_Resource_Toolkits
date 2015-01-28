//
//  SeniorLocationMessageCell.m
//  companion
//
//  Created by qiyue song on 28/11/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "SeniorLocationMessageCell.h"

@implementation SeniorLocationMessageCell

- (void)awakeFromNib {
    // Initialization code
    self.MessageDate.font = [UIFont fontWithName:@"OpenSansLight-Italic" size:15.0];
    self.MessageContent.font = [UIFont fontWithName:@"OpenSans" size:17.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
