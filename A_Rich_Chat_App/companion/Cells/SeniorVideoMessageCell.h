//
//  SeniorVideoMessageCell.h
//  companion
//
//  Created by qiyue song on 14/1/15.
//  Copyright (c) 2015 silverline. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SeniorVideoMessageCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *MessageDate;
@property (weak, nonatomic) IBOutlet UIView *MessageContainer;
@property (weak, nonatomic) IBOutlet UILabel *MessageContent;
@property (weak, nonatomic) IBOutlet UIButton *VideoButton;
@property (weak, nonatomic) IBOutlet UIImageView *MessageVideoPhoto;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *VideoLoadingView;
@property (assign) BOOL downloading;

@end
