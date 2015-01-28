//
//  MessageCell.m
//  Silverline Companion
//
//  Created by qiyue song on 7/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import "MessageCell.h"

@implementation MessageCell

- (void)awakeFromNib {
    // Initialization code
    self.messageUsername.font = [UIFont fontWithName:@"OpenSans-Bold" size:20.0];
    self.messageContent.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    self.messageDate.font = [UIFont fontWithName:@"OpenSans-Light" size:16.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
