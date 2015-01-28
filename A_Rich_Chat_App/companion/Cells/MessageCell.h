//
//  MessageCell.h
//  Silverline Companion
//
//  Created by qiyue song on 7/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *messagePhoto;
@property (weak, nonatomic) IBOutlet UILabel *messageUsername;
@property (weak, nonatomic) IBOutlet UILabel *messageContent;
@property (weak, nonatomic) IBOutlet UILabel *messageDate;
@end
