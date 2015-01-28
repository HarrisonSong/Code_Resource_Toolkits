//
//  SeniorPhotoMessageCell.h
//  companion
//
//  Created by qiyue song on 28/11/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SeniorPhotoMessageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *MessageContent;
@property (weak, nonatomic) IBOutlet UIImageView *MessagePhoto;
@property (weak, nonatomic) IBOutlet UILabel *MessageDate;
@property (weak, nonatomic) IBOutlet UIView *MessageContainer;
@property (weak, nonatomic) IBOutlet UIButton *MapButton;
@property (weak, nonatomic) IBOutlet UIButton *ImageButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *PhotoLoadingView;

@end
