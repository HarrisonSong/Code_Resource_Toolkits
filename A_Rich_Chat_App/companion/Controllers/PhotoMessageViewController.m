//
//  PhotoMessageViewController.m
//  companion
//
//  Created by qiyue song on 25/11/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "PhotoMessageViewController.h"
#import "InboxViewController.h"
#import "Senior.h"
#import "Message.h"
#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <PromiseKit/PromiseKit.h>

@interface PhotoMessageViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *ImageButton;
@property (weak, nonatomic) IBOutlet UIImageView *PhotoBackground;
@property (weak, nonatomic) IBOutlet UITextView *MessageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *UploadingView;
@property (strong, nonatomic) PFFile * uploadedImageThumbFile;
@property (strong, nonatomic) PFFile * uploadedImageFile;
@property BOOL hasFinishedUploading;

@end

@implementation PhotoMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Photo Message", @"photo message page title");
    UIBarButtonItem * sendButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", @"send text") style:UIBarButtonItemStylePlain target:self action:@selector(sendPhotoMessage)];
    [sendButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:18.0]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = sendButtonItem;
    self.PhotoBackground.image = self.photo;
    self.MessageView.font = [UIFont fontWithName:@"OpenSans" size:15.0];
    self.MessageView.text = NSLocalizedString(@"Message ...", @"message placeholder");
    self.MessageView.delegate = self;
    [self.ImageButton addTarget:self action:@selector(uploadPhoto) forControlEvents:UIControlEventTouchDown];
    [self uploadPhoto];
    
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row == 0){
        return 322;
    }else{
        return self.view.frame.size.height - 322;
    }
}

#pragma mark - UITextView Delegate
- (void)textViewDidBeginEditing:(UITextView *)textView{
    self.MessageView.textColor = [UIColor blackColor];
    self.MessageView.text = @"";
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if(self.MessageView.text.length == 0){
        self.MessageView.text = NSLocalizedString(@"Message ...", @"message placeholder");
        self.MessageView.textColor = [UIColor colorWithRed:170/255.0 green:170/255.0 blue:170/255.0 alpha:1.0];
    }
}

#pragma mark - helper methods
- (void)uploadPhoto{
    self.hasFinishedUploading = NO;
    self.ImageButton.enabled = NO;
    self.PhotoBackground.alpha = 0.3;
    self.UploadingView.hidesWhenStopped = YES;
    [self.UploadingView startAnimating];
    self.uploadedImageFile = [PFFile fileWithName:@"photo.jpg" data:UIImageJPEGRepresentation(self.photo, 0.8)];
    PMKPromise * largePhotoUploadPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [self.uploadedImageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(succeeded){
                fulfill(@"successfully");
            }else{
                reject(error);
            }
        }];
    }];
    PMKPromise * thumbPhotoUploadPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        CGSize destinationSize = CGSizeMake(100, 150);
        UIGraphicsBeginImageContext(destinationSize);
        [self.photo drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
        UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.uploadedImageThumbFile = [PFFile fileWithName:@"thumb.jpg" data:UIImageJPEGRepresentation(thumbImage, 1)];
        [self.uploadedImageThumbFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(succeeded){
                fulfill(@"successfully");
            }else{
                reject(error);
            }
        }];
    }];
    PhotoMessageViewController __weak * weakSelf = self;
    [PMKPromise when:@[largePhotoUploadPromise, thumbPhotoUploadPromise]].then(^(NSArray * results){
        weakSelf.hasFinishedUploading = YES;
        weakSelf.PhotoBackground.alpha = 1;
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Successfully upload!", @"successful upload Alert")];
    }).catch(^(NSError *error){
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to upload the photo. Please try again by tapping the photo.", @"upload photo error message")];
        weakSelf.ImageButton.enabled = YES;
        weakSelf.PhotoBackground.alpha = 0.8;
    }).finally(^{
        [weakSelf.UploadingView stopAnimating];
    });
}

- (void)sendPhotoMessage{
    [self.view endEditing:YES];
    if(!self.hasFinishedUploading){
        [SVProgressHUD showImage:[UIImage imageNamed:@"AlertIcon"] status:NSLocalizedString(@"Please wait to finish uploading the photo.", @"")];
    }else{
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
        Message * newMessage = [Message object];
        newMessage.isPending = YES;
        newMessage.isRead = NO;
        if([self.MessageView.text isEqualToString:NSLocalizedString(@"Message ...", @"message placeholder")]){
            newMessage.messageData = @"";
        }else{
            newMessage.messageData = self.MessageView.text;
        }
        newMessage.receiverId = self.senior.objectId;
        newMessage.senderId = [PFUser currentUser].objectId;
        newMessage.type = @"up";
        newMessage.messageImg = self.uploadedImageFile;
        newMessage.messageImgThumb = self.uploadedImageThumbFile;
        PhotoMessageViewController __weak * weakSelf = self;
        [newMessage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(succeeded){
                NSDictionary *data = @{@"alert":newMessage.messageData, @"badge":@"Increment", @"title":NSLocalizedString(@"Silverline Companion", @"application name"), @"t": @"up", @"pid":newMessage.objectId, @"n":[PFUser currentUser][@"name"], @"action":@"com.silverline.companion.UPDATE_STATUS"};
                PFPush *push = [[PFPush alloc] init];
                [push setData:data];
                PFQuery *pushQuery = [PFInstallation query];
                [pushQuery whereKey:@"owner" equalTo:weakSelf.senior.objectId];
                [push setQuery:pushQuery];
                [push sendPushInBackground];
                InboxViewController * InboxVC = weakSelf.navigationController.childViewControllers[ (weakSelf.navigationController.childViewControllers.count - 2)];
                [InboxVC.messagesList addObject:newMessage];
                [InboxVC.TableView reloadData];
                NSIndexPath * lastIndex = [NSIndexPath indexPathForRow:(InboxVC.messagesList.count - 1) inSection:0];
                [InboxVC.TableView scrollToRowAtIndexPath:lastIndex atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                [SVProgressHUD dismiss];
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }else{
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to send the message. Please try again.", @"send message error message")];
            }
        }];
    }
}

@end
