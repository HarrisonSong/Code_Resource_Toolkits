//
//  SeniorVideoMessageCell.m
//  companion
//
//  Created by qiyue song on 14/1/15.
//  Copyright (c) 2015 silverline. All rights reserved.
//

#import "SeniorVideoMessageCell.h"

@implementation SeniorVideoMessageCell

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
