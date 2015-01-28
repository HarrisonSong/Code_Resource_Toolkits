//
//  SeniorMessageCell.h
//  companion
//
//  Created by qiyue song on 21/11/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SeniorMessageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *MessageDate;
@property (weak, nonatomic) IBOutlet UILabel *MessageContent;
@property (weak, nonatomic) IBOutlet UIView *MessageContainer;

@end
