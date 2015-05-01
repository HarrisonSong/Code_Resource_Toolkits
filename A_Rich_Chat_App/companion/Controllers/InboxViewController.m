//
//  InboxViewController.m
//  companion
//
//  Created by qiyue song on 24/11/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "InboxViewController.h"
#import "WellBeingViewController.h"
#import "PhotoMessageViewController.h"
#import "VideoMessageViewController.h"
#import "LocationViewController.h"
#import "Message.h"
#import "shareItemManager.h"
#import "SeniorMessageCell.h"
#import "SeniorPhotoMessageCell.h"
#import "SeniorLocationMessageCell.h"
#import "MyMessageCell.h"
#import "MyPhotoMessageCell.h"
#import "SeniorVideoMessageCell.h"
#import "MyVideoMessageCell.h"
#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <GGFullscreenImageViewController/GGFullScreenImageViewController.h>
#import <PromiseKit/PromiseKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AWSS3.h>
#import "Credential.h"

#define MESSAGE_CONTAINER_CORNER_RADIUS 5
#define MESSAGE_IMAGE_CORNER_RADIUS 4
#define MESSAGES_BUNCH_COUNT 10
#define SYSTEM_VERSION_LESS_THAN(v)    ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface InboxViewController () <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *InputContainer;
@property (weak, nonatomic) IBOutlet UITextView *MessageInputBox;
@property (weak, nonatomic) IBOutlet UIButton *PhotoButton;
@property NSInteger resendIndex;
@property NSInteger skipCount;
@property UIRefreshControl *refreshControl;
@property BOOL hasLoadedAll;

@property(nonatomic, strong) AWSS3TransferManager * S3TransferManager;
@property(nonatomic, strong) AWSS3TransferManagerDownloadRequest *downloadRequest;

@property(nonatomic, strong) MPMoviePlayerController * videoPlayer;

- (IBAction)onPhotoButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *InputContainerBottomConstraint;

@end

@implementation InboxViewController

- (NSMutableArray *)messagesList{
    if(_messagesList == nil) _messagesList = [NSMutableArray array];
    return _messagesList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Update all unread messages read status
    [self updateAllMessageReadStatus];
    
    // Initialization part
    self.TableView.delegate = self;
    self.TableView.dataSource = self;
    self.MessageInputBox.delegate = self;
    if(self.senior.name){
        self.navigationItem.title = self.senior.name;
    }
    if(self.senior.profileImage){
        InboxViewController __weak * weakSelf = self;
        [self.senior.profileImage getDataInBackgroundWithBlock:^(NSData * data, NSError *error) {
            if(!error && data){
                UIImage * profileImage = [UIImage imageWithData:data];
                UIButton * rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
                rightButton.bounds = CGRectMake(0,0,35,35);
                [rightButton setImage:profileImage forState:UIControlStateNormal];
                [rightButton addTarget:weakSelf action:@selector(WellBeing) forControlEvents:UIControlEventTouchDown];
                UIBarButtonItem * rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
                weakSelf.navigationItem.rightBarButtonItem = rightItem;
            }
        }];
    }
    self.resendIndex = -1;
    self.skipCount = 0;
    self.hasLoadedAll = NO;
    self.MessageInputBox.font = [UIFont fontWithName:@"OpenSans" size:15.0];
    self.MessageInputBox.text = NSLocalizedString(@"Message ...", @"message placeholder");
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 5, 0, 0)];
    [self.TableView insertSubview:refreshView atIndex:0];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadMore) forControlEvents:UIControlEventValueChanged];
    [refreshView addSubview:self.refreshControl];
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [self reloadMessagesList];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveRemoteNotification:)
     name:@"UIApplicationDidReceiveRemoteAsNotification"
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveRemoteNotification:)
     name:@"UIApplicationDidReceiveRemoteCiNotification"
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveRemoteNotification:)
     name:@"UIApplicationDidReceiveRemoteMrNotification"
     object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)viewWillDisappear:(BOOL)animated{
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        if(self.delegate){
            [self.delegate recoveryNotificationListener];
            [self updateTabBarBadgeNumber];
        }else{
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"updateConversation"
             object:self
             userInfo:@{@"seniorId":self.senior.objectId}];
        }
    }
    
    [super viewWillDisappear:animated];
    
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.messagesList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Message * currentMessage = self.messagesList[indexPath.row];
    if([currentMessage.senderId isEqualToString:[PFUser currentUser].objectId]){
        // Mine Messages
        if([currentMessage.type isEqualToString:@"vd"] && !SYSTEM_VERSION_LESS_THAN(@"7.0")){ // Video Message
            MyVideoMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyVideoMessageCell"];
            if(cell == nil){
                NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"MyVideoMessageCell" owner:self options:nil];
                cell = objects[0];
            }
            cell.MessageVideoPhoto.clipsToBounds = YES;
            cell.PlayVideoButton.tag = indexPath.row;
            [cell.PlayVideoButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
            if([[NSFileManager defaultManager] fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:currentMessage.videoUrl]]){
                MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:currentMessage.videoUrl]]];
                UIImage * thumbnail = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
                [player stop];
                cell.MessageVideoPhoto.image = thumbnail;
                cell.VideoLoadingView.hidden = YES;
            }else{
                // Download Video
                if(!cell.downloading){
                    cell.downloading = YES;
                    cell.PlayVideoButton.enabled = NO;
                    cell.VideoLoadingView.hidesWhenStopped = YES;
                    [cell.VideoLoadingView startAnimating];
                    self.downloadRequest = [AWSS3TransferManagerDownloadRequest new];
                    self.downloadRequest.bucket = S3BucketName;
                    self.downloadRequest.key = currentMessage.videoUrl;
                    self.downloadRequest.downloadingFileURL = [NSURL fileURLWithPath: [NSTemporaryDirectory() stringByAppendingPathComponent:currentMessage.videoUrl]];
                    [[[AWSS3TransferManager defaultS3TransferManager] download:self.downloadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                        if(task.error != nil){
                            NSLog(@"Failed to download video %@", currentMessage.videoUrl);
                        }else{
                            MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:currentMessage.videoUrl]]];
                            UIImage * thumbnail = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
                            [player stop];
                            cell.MessageVideoPhoto.image = thumbnail;
                        }
                        [cell.VideoLoadingView stopAnimating];
                        cell.PlayVideoButton.enabled = YES;
                        cell.downloading = NO;
                        return nil;
                    }];
                }
            }
            cell.MessageContent.text = currentMessage.messageData;
            cell.MessageDate.text = [NSString stringWithFormat:@"You, %@", [NSDateFormatter localizedStringFromDate:currentMessage.createdAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
            cell.MessageContainer.layer.cornerRadius = MESSAGE_CONTAINER_CORNER_RADIUS;
            cell.MessageVideoPhoto.layer.cornerRadius = MESSAGE_IMAGE_CORNER_RADIUS;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }else if([currentMessage.type isEqualToString:@"up"]){  // Photo Message
            MyPhotoMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyPhotoMessageCell"];
            if (cell == nil) {
                NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"MyPhotoMessageCell" owner:self options:nil];
                cell = objects[0];
            }
            cell.MessagePhoto.clipsToBounds = YES;
            cell.PhotoLoadingView.hidesWhenStopped = YES;
            [cell.PhotoLoadingView startAnimating];
            cell.ImageButton.enabled = NO;
            cell.ImageButton.tag = indexPath.row;
            [cell.ImageButton addTarget:self action:@selector(showFullScreen:) forControlEvents:UIControlEventTouchDown];
            NSString * imageKey = [NSString stringWithFormat:@"%@-%@",self.senior.objectId, currentMessage.objectId];
            if(![[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageKey]){
                [currentMessage.messageImg getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if(!error && data){
                        UIImage * downloadedImage = [UIImage imageWithData:data];
                        cell.MessagePhoto.image = downloadedImage;
                        [cell.PhotoLoadingView stopAnimating];
                        cell.ImageButton.enabled = YES;
                        [[SDImageCache sharedImageCache] storeImage:downloadedImage forKey:imageKey toDisk:YES];
                    }else{
                        // TO DO: handle the error case and retry function.
                    }
                }];
            }else{
                cell.MessagePhoto.image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageKey];
                [((UIActivityIndicatorView *)cell.MessageContainer.subviews[1]) stopAnimating];
                cell.ImageButton.enabled = YES;
            }
            cell.MessageContent.text = currentMessage.messageData;
            cell.MessageDate.text = [NSString stringWithFormat:NSLocalizedString(@"You, %@", @"my message date"), [NSDateFormatter localizedStringFromDate:currentMessage.createdAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
            cell.MessageContainer.layer.cornerRadius = MESSAGE_CONTAINER_CORNER_RADIUS;
            cell.MessagePhoto.layer.cornerRadius = MESSAGE_IMAGE_CORNER_RADIUS;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }else{  //Plain Text Message
            MyMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyMessageCell"];
            if (cell == nil) {
                NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"MyMessageCell" owner:self options:nil];
                cell = objects[0];
            }
            if([currentMessage.type isEqualToString:@"vd"] && SYSTEM_VERSION_LESS_THAN(@"7.0") && [currentMessage.messageData isEqualToString:@""]){
                cell.MessageContent.text = NSLocalizedString(@"video", @"placeholder for video message on iOS6");
            }else{
                cell.MessageContent.text = currentMessage.messageData;
            }
            cell.MessageDate.text = [NSString stringWithFormat:NSLocalizedString(@"You, %@", @"my message date"), [NSDateFormatter localizedStringFromDate:currentMessage.createdAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
            if(currentMessage.createdAt){
                cell.MessageDate.text = [NSString stringWithFormat:NSLocalizedString(@"You, %@", @"my message date"), [NSDateFormatter localizedStringFromDate:currentMessage.createdAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
                cell.LoadingView.hidden = YES;
                cell.FailedButton.hidden = YES;
            }else{
                cell.MessageDate.text = [NSString stringWithFormat:NSLocalizedString(@"You, %@", @"my message date"), [NSDateFormatter localizedStringFromDate:[NSDate new] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
                [cell.LoadingView startAnimating];
                [cell.LoadingView setHidesWhenStopped:YES];
                cell.FailedButton.hidden = YES;
                cell.FailedButton.tag = indexPath.row;
            }
            cell.MessageContainer.layer.cornerRadius = MESSAGE_CONTAINER_CORNER_RADIUS;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    }else{
        // Senior Messages
        if([currentMessage.type isEqualToString:@"vd"] && !SYSTEM_VERSION_LESS_THAN(@"7.0")){ // Video Message
            SeniorVideoMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SeniorVideoMessageCell"];
            if(cell == nil){
                NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"SeniorVideoMessageCell" owner:self options:nil];
                cell = objects[0];
            }
            cell.MessageVideoPhoto.clipsToBounds = YES;
            cell.VideoButton.tag = indexPath.row;
            [cell.VideoButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
            if([[NSFileManager defaultManager] fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:currentMessage.videoUrl]]){
                MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:currentMessage.videoUrl]]];
                UIImage * thumbnail = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
                [player stop];
                cell.MessageVideoPhoto.image = thumbnail;
                cell.VideoLoadingView.hidden = YES;
            }else{
                // Download Video
                if(!cell.downloading){
                    cell.downloading = YES;
                    cell.VideoButton.enabled = NO;
                    cell.VideoLoadingView.hidesWhenStopped = YES;
                    [cell.VideoLoadingView startAnimating];
                    self.downloadRequest = [AWSS3TransferManagerDownloadRequest new];
                    self.downloadRequest.bucket = S3BucketName;
                    self.downloadRequest.key = currentMessage.videoUrl;
                    self.downloadRequest.downloadingFileURL = [NSURL fileURLWithPath: [NSTemporaryDirectory() stringByAppendingPathComponent:currentMessage.videoUrl]];
                    [[[AWSS3TransferManager defaultS3TransferManager] download:self.downloadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                        if(task.error != nil){
                            NSLog(@"Failed to download video %@", currentMessage.videoUrl);
                        }else{
                            MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:currentMessage.videoUrl]]];
                            UIImage * thumbnail = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
                            [player stop];
                            cell.MessageVideoPhoto.image = thumbnail;
                        }
                        [cell.VideoLoadingView stopAnimating];
                        cell.VideoButton.enabled = YES;
                        cell.downloading = NO;
                        return nil;
                    }];
                }
            }
            cell.MessageContent.text = currentMessage.messageData;
            cell.MessageDate.text = [NSString stringWithFormat:@"%@, %@",self.senior.name, [NSDateFormatter localizedStringFromDate:currentMessage.createdAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
            cell.MessageContainer.layer.cornerRadius = MESSAGE_CONTAINER_CORNER_RADIUS;
            cell.MessageVideoPhoto.layer.cornerRadius = MESSAGE_IMAGE_CORNER_RADIUS;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }else if([currentMessage.type isEqualToString:@"up"]){ // Photo Message
            // Remarks: Here we don't use dequeueReusableCellWithIdentifier because the
            // MapButton may be removed and cannot be reused by other cells.
            NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"SeniorPhotoMessageCell" owner:self options:nil];
            SeniorPhotoMessageCell *cell = objects[0];
            if(!currentMessage.location){
                [cell.MapButton removeFromSuperview];
            }else{
                cell.MapButton.tag = indexPath.row;
                [cell.MapButton addTarget:self action:@selector(loadLocation:) forControlEvents:UIControlEventTouchUpInside];
                
            }
            cell.MessagePhoto.clipsToBounds = YES;
            cell.PhotoLoadingView.hidesWhenStopped = YES;
            [cell.PhotoLoadingView startAnimating];
            cell.ImageButton.enabled = NO;
            cell.ImageButton.tag = indexPath.row;
            [cell.ImageButton addTarget:self action:@selector(showFullScreen:) forControlEvents:UIControlEventTouchDown];
            NSString * imageKey = [NSString stringWithFormat:@"%@-%@",self.senior.objectId, currentMessage.objectId];
            if(![[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageKey]){
                [currentMessage.messageImg getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if(!error && data){
                        UIImage * downloadedImage = [UIImage imageWithData:data];
                        cell.MessagePhoto.image = downloadedImage;
                        [cell.PhotoLoadingView stopAnimating];
                        cell.ImageButton.enabled = YES;
                        [[SDImageCache sharedImageCache] storeImage:downloadedImage forKey:imageKey toDisk:YES];
                    }else{
                        // TO DO: handle the error case and retry function.
                    }
                }];
            }else{
                cell.MessagePhoto.image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageKey];
                [cell.PhotoLoadingView stopAnimating];
                cell.ImageButton.enabled = YES;
            }
            cell.MessageContent.text = currentMessage.messageData;
            cell.MessageDate.text = [NSString stringWithFormat:@"%@, %@",self.senior.name, [NSDateFormatter localizedStringFromDate:currentMessage.createdAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
            cell.MessageContainer.layer.cornerRadius = MESSAGE_CONTAINER_CORNER_RADIUS;
            cell.MessagePhoto.layer.cornerRadius = MESSAGE_IMAGE_CORNER_RADIUS;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }else if([currentMessage.type isEqualToString:@"as"] || ([currentMessage.type isEqualToString:@"mr"] && currentMessage.location)){ // Add Companion Message or Message With Location
            
            // Remarks: Here we don't use dequeueReusableCellWithIdentifier because the
            // MapButton may be removed and cannot be reused by other cells.
            NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"SeniorLocationMessageCell" owner:self options:nil];
            SeniorLocationMessageCell * cell = objects[0];
            cell.MessageContent.text = currentMessage.messageData;
            cell.MessageDate.text = [NSString stringWithFormat:@"%@, %@",self.senior.name, [NSDateFormatter localizedStringFromDate:currentMessage.createdAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
            if(!currentMessage.location){
                [cell.MapButton removeFromSuperview];
            }else{
                cell.MapButton.tag = indexPath.row;
                [cell.MapButton addTarget:self action:@selector(loadLocation:) forControlEvents:UIControlEventTouchUpInside];
            }
            cell.MessageContainer.layer.cornerRadius = MESSAGE_CONTAINER_CORNER_RADIUS;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }else{ // Plain Text Message
            SeniorMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SeniorMessageCell"];
            if (cell == nil) {
                NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"SeniorMessageCell" owner:self options:nil];
                cell = objects[0];
            }
            if([currentMessage.type isEqualToString:@"vd"] && SYSTEM_VERSION_LESS_THAN(@"7.0") && [currentMessage.messageData isEqualToString:@""]){
                    cell.MessageContent.text = NSLocalizedString(@"video", @"placeholder for video message on iOS6");
            }else{
                cell.MessageContent.text = currentMessage.messageData;
            }
            cell.MessageDate.text = [NSString stringWithFormat:@"%@, %@", self.senior.name, [NSDateFormatter localizedStringFromDate:currentMessage.createdAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
            cell.MessageContainer.layer.cornerRadius = MESSAGE_CONTAINER_CORNER_RADIUS;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    Message * currentMessage = (Message *)self.messagesList[indexPath.row];
    if([currentMessage.type isEqualToString:@"up"]|| [currentMessage.type isEqualToString:@"vd"]){
        CGSize constraint = CGSizeMake(240.0f, 20000.0f);
        CGSize size = [currentMessage.messageData sizeWithFont:[UIFont fontWithName:@"OpenSans" size:17.0f] constrainedToSize:constraint lineBreakMode:NSLineBreakByTruncatingTail];
        return size.height + 324;
    }else if([currentMessage.type isEqualToString:@"as"] || ([currentMessage.type isEqualToString:@"mr"] && currentMessage.location)){
        CGSize constraint = CGSizeMake(181.0f, 20000.0f);
        CGSize size = [currentMessage.messageData sizeWithFont:[UIFont fontWithName:@"OpenSans" size:17.0f] constrainedToSize:constraint lineBreakMode:NSLineBreakByTruncatingTail];
        return MAX(size.height, 54.0) + 60;
    }else{
        CGSize constraint = CGSizeMake(266.0f, 20000.0f);
        CGSize size = [currentMessage.messageData sizeWithFont:[UIFont fontWithName:@"OpenSans" size:17.0f] constrainedToSize:constraint lineBreakMode:NSLineBreakByTruncatingTail];
        return size.height + 60;
    }
}

#pragma mark - UITextView Delegate
- (void)textViewDidBeginEditing:(UITextView *)textView{
    self.MessageInputBox.text = @"";
    self.MessageInputBox.textColor = [UIColor blackColor];
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if(self.MessageInputBox.text.length == 0){
        self.MessageInputBox.text = NSLocalizedString(@"Message ...", @"message placeholder");
        self.MessageInputBox.textColor = [UIColor colorWithRed:170.0/255.0 green:170.0/255.0 blue:170.0/255.0 alpha:1.0];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    BOOL shouldChangeText = YES;
    if ([text isEqualToString:@"\n"]) {
        Message * newMessage = [Message object];
        newMessage.isPending = YES;
        newMessage.isRead = NO;
        newMessage.messageData = self.MessageInputBox.text;
        self.MessageInputBox.text = @"";
        newMessage.receiverId = self.senior.objectId;
        newMessage.senderId = [PFUser currentUser].objectId;
        newMessage.type = @"mr";
        [self.messagesList addObject:newMessage];
        NSIndexPath * newIndexPath = [NSIndexPath indexPathForRow:(self.messagesList.count - 1) inSection:0];
        [self.TableView beginUpdates];
        [self.TableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationBottom];
        [self.TableView endUpdates];
        [self.TableView scrollToRowAtIndexPath:newIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        InboxViewController __weak * weakSelf = self;
        [newMessage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            MyMessageCell * currentCell = (MyMessageCell *)[weakSelf.TableView cellForRowAtIndexPath:newIndexPath];
            [currentCell.LoadingView stopAnimating];
            if(succeeded){
                NSDictionary *data = @{@"alert":newMessage.messageData, @"badge":@"Increment", @"title":NSLocalizedString(@"Silverline Companion", @"application name"), @"t": @"mr", @"pid":newMessage.objectId, @"action":@"com.silverline.companion.UPDATE_STATUS"};
                PFPush *push = [[PFPush alloc] init];
                [push setData:data];
                PFQuery *pushQuery = [PFInstallation query];
                [pushQuery whereKey:@"owner" equalTo:weakSelf.senior.objectId];
                [push setQuery:pushQuery];
                [push sendPushInBackground];
                [self.delegate insertConversationContent:newMessage inboxSeniorId:self.senior.objectId];
            }else{
                currentCell.FailedButton.hidden = NO;
                [currentCell.FailedButton addTarget:weakSelf action:@selector(retrySendingMessage:) forControlEvents:UIControlEventTouchDown];
            }
        }];
        shouldChangeText = NO;  
    }
    return shouldChangeText;  
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(![actionSheet.title isEqualToString:NSLocalizedString(@"Do you want to resend the message?", @"resend message action sheet content")]){
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            if(SYSTEM_VERSION_LESS_THAN(@"7.0")){
                if(buttonIndex != 2){
                    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
                }
            }else{
                if(buttonIndex != 3){
                    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
                }
            }
        }else{
            if(buttonIndex != 1){
                [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
            }
        }
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(![actionSheet.title isEqualToString:NSLocalizedString(@"Do you want to resend the message?", @"resend message action sheet content")]){
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePickerController.delegate = self;
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
            if(SYSTEM_VERSION_LESS_THAN(@"7.0")){
                switch(buttonIndex){
                    case 0:
                    {
                        // Show Photo Taken page
                        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                        [SVProgressHUD dismiss];
                        [self presentViewController:imagePickerController animated:YES completion:nil];
                        break;
                    }
                    case 1:
                    {
                        // Show Select Photo page
                        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                        [SVProgressHUD dismiss];
                        [self presentViewController:imagePickerController animated:YES completion:nil];
                        break;
                    }
                    default:
                    {
                        [SVProgressHUD dismiss];
                        break;
                    }
                }
            }else{
                switch(buttonIndex){
                    case 0:
                    {
                        // Show Photo Taken page
                        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                        [SVProgressHUD dismiss];
                        [self presentViewController:imagePickerController animated:YES completion:nil];
                        break;
                    }
                    case 1:
                    {
                        // Show Select Video page
                        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                        imagePickerController.mediaTypes = @[(NSString *)kUTTypeMovie];
                        imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
                        [SVProgressHUD dismiss];
                        [self presentViewController:imagePickerController animated:YES completion:nil];
                        break;
                    }
                    case 2:
                    {
                        // Show Select Photo page
                        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                        [SVProgressHUD dismiss];
                        [self presentViewController:imagePickerController animated:YES completion:nil];
                        break;
                    }
                    default:
                    {
                        [SVProgressHUD dismiss];
                        break;
                    }
                }
            }
        }else{
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [SVProgressHUD dismiss];
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
    }else{
        [self.TableView beginUpdates];
        MyMessageCell * currentCell = (MyMessageCell *)[self.TableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.resendIndex inSection:0]];
        currentCell.LoadingView.hidden = NO;
        [currentCell.LoadingView startAnimating];
        currentCell.FailedButton.hidden = YES;
        [self.TableView endUpdates];
        InboxViewController __weak * weakSelf = self;
        [(Message *)self.messagesList.lastObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [currentCell.LoadingView stopAnimating];
            if(succeeded){
                NSDictionary *data = @{@"alert":((Message *)weakSelf.messagesList.lastObject).messageData, @"badge":@"Increment", @"title":NSLocalizedString(@"Silverline Companion", @"application name"), @"t": @"mr", @"pid":((Message *)weakSelf.messagesList.lastObject).objectId, @"action":@"com.silverline.companion.UPDATE_STATUS"};
                PFPush *push = [[PFPush alloc] init];
                [push setData:data];
                PFQuery *pushQuery = [PFInstallation query];
                [pushQuery whereKey:@"owner" equalTo:weakSelf.senior.objectId];
                [push setQuery:pushQuery];
                [push sendPushInBackground];
            }else{
                currentCell.FailedButton.hidden = NO;
            }
        }];
    }
}

#pragma mark - UIImagePickerController Delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    InboxViewController __weak * weakSelf = self;
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    [picker dismissViewControllerAnimated:YES completion:^{
        if([[info valueForKey:UIImagePickerControllerMediaType] isEqualToString:@"public.movie"]){
            NSURL * videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
            VideoMessageViewController * VideoMessageVC = [storyboard instantiateViewControllerWithIdentifier:@"VideoMessage"];
            VideoMessageVC.videoUrl = videoUrl;
            VideoMessageVC.senior = weakSelf.senior;
            [weakSelf.navigationController pushViewController:VideoMessageVC animated:YES];
        }else{UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
            PhotoMessageViewController * PhotoMessageVC = [storyboard instantiateViewControllerWithIdentifier:@"PhotoMessage"];
            PhotoMessageVC.photo = image;
            PhotoMessageVC.senior = weakSelf.senior;
            [weakSelf.navigationController pushViewController:PhotoMessageVC animated:YES];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - helper methods
- (void)WellBeing{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    WellBeingViewController * WellBeingVC = [storyboard instantiateViewControllerWithIdentifier:@"WellBeing"];
    WellBeingVC.hidesBottomBarWhenPushed = YES;
    WellBeingVC.senior = self.senior;
    [self.navigationController pushViewController:WellBeingVC animated:YES];
}

- (void)dismissKeyboard{
    [self.view endEditing:YES];
}

- (void)reloadMessagesList{
    PFQuery * messageQuery1 = [PFQuery queryWithClassName:@"PushMessage"];
    [messageQuery1 whereKey:@"senderId" equalTo:[PFUser currentUser].objectId];
    [messageQuery1 whereKey:@"receiverId" equalTo:self.senior.objectId];
    PFQuery * messageQuery2 = [PFQuery queryWithClassName:@"PushMessage"];
    [messageQuery2 whereKey:@"receiverId" equalTo:[PFUser currentUser].objectId];
    [messageQuery2 whereKey:@"senderId" equalTo:self.senior.objectId];
    PFQuery * messagesQeury = [PFQuery orQueryWithSubqueries:@[messageQuery1, messageQuery2]];
    [messagesQeury setSkip:0];
    [messagesQeury setLimit:MESSAGES_BUNCH_COUNT];
    [messagesQeury orderByDescending:@"createdAt"];
    InboxViewController __weak * weakSelf = self;
    [messagesQeury findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error && objects.count > 0){
            [weakSelf.messagesList removeAllObjects];
            NSEnumerator *enumerator = [objects reverseObjectEnumerator];
            for(Message * message in enumerator){
                [weakSelf.messagesList addObject:message];
            }
            [weakSelf.TableView reloadData];
            weakSelf.skipCount = objects.count;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSIndexPath* indexPath = [NSIndexPath indexPathForRow:(self.messagesList.count - 1) inSection:0];
                [self.TableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            });
            [SVProgressHUD dismiss];
        }else{
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Have not retrieved any message.", @"not receiving any message alert")];
        }
        if(objects && objects.count < MESSAGES_BUNCH_COUNT){
            weakSelf.hasLoadedAll = YES;
        }
    }];
}

- (void)loadMore{
    if(self.hasLoadedAll){
        [self.refreshControl endRefreshing];
    }else{
        PFQuery * messageQuery1 = [PFQuery queryWithClassName:@"PushMessage"];
        [messageQuery1 whereKey:@"senderId" equalTo:[PFUser currentUser].objectId];
        [messageQuery1 whereKey:@"receiverId" equalTo:self.senior.objectId];
        PFQuery * messageQuery2 = [PFQuery queryWithClassName:@"PushMessage"];
        [messageQuery2 whereKey:@"receiverId" equalTo:[PFUser currentUser].objectId];
        [messageQuery2 whereKey:@"senderId" equalTo:self.senior.objectId];
        PFQuery * messagesQeury = [PFQuery orQueryWithSubqueries:@[messageQuery1, messageQuery2]];
        [messagesQeury orderByDescending:@"createdAt"];
        [messagesQeury setSkip:self.skipCount];
        [messagesQeury setLimit:MESSAGES_BUNCH_COUNT];
        InboxViewController __weak * weakSelf = self;
        [messagesQeury findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if(!error && objects.count > 0){
                for(Message * message in objects){
                    [weakSelf.messagesList insertObject:message atIndex:0];
                }
                weakSelf.skipCount += objects.count;
                [weakSelf.TableView beginUpdates];
                NSMutableArray * indexArray = [NSMutableArray array];
                for(int i = 0; i < objects.count; i++){
                    [indexArray addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
                [weakSelf.TableView insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationTop];
                [weakSelf.TableView endUpdates];
            }
            if(objects && objects.count < MESSAGES_BUNCH_COUNT){
                weakSelf.hasLoadedAll = YES;
            }
            [weakSelf.refreshControl endRefreshing];
        }];
    }
}

- (void)keyboardWillShow:(NSNotification *)notif{
    self.InputContainerBottomConstraint.constant = - [[notif.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    [self.InputContainer setNeedsUpdateConstraints];
    [self.TableView setNeedsUpdateConstraints];
    [UIView animateWithDuration:[notif.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        [self.InputContainer layoutIfNeeded];
        [self.TableView layoutIfNeeded];
        if(self.TableView.contentSize.height > self.TableView.frame.size.height){
            CGPoint offset = CGPointMake(0, self.TableView.contentSize.height - self.TableView.frame.size.height);
            [self.TableView setContentOffset:offset animated:YES];
        }
    }];
}

- (void)keyboardWillHide:(NSNotification *)notif{
    self.InputContainerBottomConstraint.constant = 0;
    [self.InputContainer setNeedsUpdateConstraints];
    [self.TableView setNeedsUpdateConstraints];
    [UIView animateWithDuration:[notif.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
        [self.InputContainer layoutIfNeeded];
        [self.TableView layoutIfNeeded];
    }];
}

- (IBAction)onPhotoButtonPressed:(id)sender {
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        if(!SYSTEM_VERSION_LESS_THAN(@"7.0")){
            UIActionSheet * mediaTakenSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select one media resource", @"media resource action sheet content") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Take Photo", @"take photo"), NSLocalizedString(@"Take Video", @"take video"), NSLocalizedString(@"Choose from Library", @"choose from library"), nil];
            [mediaTakenSheet showInView:self.view];
        }else{
            UIActionSheet * mediaTakenSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select one media resource", @"media resource action sheet content") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Take Photo", @"take photo"), NSLocalizedString(@"Choose from Library", @"choose from library"), nil];
            [mediaTakenSheet showInView:self.view];
        }
    }else{
        UIActionSheet * mediaTakenSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select one photo resource", @"photo resource action sheet content") delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Choose from Library", @"choose from library"), nil];
        [mediaTakenSheet showInView:self.view];
    }
}

- (void)retrySendingMessage:(UIButton *)failedButton{
    self.resendIndex = failedButton.tag;
    UIActionSheet * resendSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Do you want to resend the message?", @"resend message action sheet content") delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:NSLocalizedString(@"Resend", @"resend")otherButtonTitles:nil];
    [resendSheet showInView:self.view];
}

- (void)loadLocation:(UIButton *)button{
    Message * currentMessage = (Message *)self.messagesList[button.tag];
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LocationViewController * LocationVC = [storyboard instantiateViewControllerWithIdentifier:@"Location"];
    LocationVC.location = currentMessage.location;
    [self.navigationController pushViewController:LocationVC animated:YES];
}

- (void)showFullScreen:(UIButton *)button{
    GGFullscreenImageViewController *vc = [[GGFullscreenImageViewController alloc] init];
    NSInteger index = button.tag;
    if([((Message *)self.messagesList[index]).senderId isEqualToString:[PFUser currentUser].objectId]){
        MyPhotoMessageCell * cell = ((MyPhotoMessageCell *)[self.TableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:button.tag inSection:0]]);
        vc.liftedImageView = cell.MessageContainer.subviews[0];
    }else{
        SeniorPhotoMessageCell * cell = ((SeniorPhotoMessageCell *)[self.TableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:button.tag inSection:0]]);
        vc.liftedImageView = cell.MessageContainer.subviews[1];
    }
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)playVideo:(UIButton *)sender{
    Message * currentMessage = (Message *)self.messagesList[sender.tag];
    self.videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:currentMessage.videoUrl]]];
    self.videoPlayer.controlStyle = MPMovieControlStyleDefault;
    self.videoPlayer.shouldAutoplay = YES;
    [self.view addSubview:self.videoPlayer.view];
    [self.videoPlayer setFullscreen:YES animated:YES];
}

- (void)didReceiveRemoteNotification:(NSNotification *)notif{
    NSString * objectId = notif.userInfo[@"pid"];
    PFQuery * messageQuery = [Message query];
    [messageQuery getObjectInBackgroundWithId:objectId block:^(PFObject * object, NSError *error) {
        if(!error && object){
            [self.messagesList addObject:object];
            [self.delegate insertConversationContent:object inboxSeniorId:self.senior.objectId];
            if([((Message *)object).senderId isEqualToString:self.senior.objectId]){
                if(!((Message *)object).isRead){
                    ((Message *)object).isRead = YES;
                    [object saveInBackground];
                }
                [self.TableView beginUpdates];
                [self.TableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:(self.messagesList.count - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
                [self.TableView endUpdates];
                [self.TableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(self.messagesList.count - 1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }
    }];
}

- (void)updateTabBarBadgeNumber{
    [[shareItemManager sharedInstance] updateUnreadMessageCount:^(BOOL succeed, NSError *error) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"updateTabBarBadgeNumber"
         object:self
         userInfo:nil];
    }];
}

- (void)updateAllMessageReadStatus{
    PFQuery * messageQuery = [Message query];
    [messageQuery whereKey:@"receiverId" equalTo:[PFUser currentUser].objectId];
    [messageQuery whereKey:@"senderId" equalTo:self.senior.objectId];
    [messageQuery whereKey:@"isRead" equalTo:@NO];
    [messageQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error && objects.count){
            for(Message * message in objects){
                message.isRead = YES;
            }
            [PFObject saveAllInBackground:objects block:^(BOOL succeeded, NSError *error) {
                if(succeeded){
                    NSLog(@"Successfully update all unread messages.");
                }else{
                    NSLog(@"Failed to update all unread messages!");
                }
            }];
        }
    }];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
