//
//  VideoMessageViewController.m
//  companion
//
//  Created by qiyue song on 14/1/15.
//  Copyright (c) 2015 silverline. All rights reserved.
//

#import "VideoMessageViewController.h"
#import "InboxViewController.h"
#import "Senior.h"
#import "Message.h"
#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <PromiseKit/PromiseKit.h>

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import <AWSS3.h>
#import "Credential.h"

@interface VideoMessageViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *VideoLoadingView;
@property (weak, nonatomic) IBOutlet UIImageView *BackgroundImageView;
@property (weak, nonatomic) IBOutlet UIButton *PlayVideoButton;
@property (weak, nonatomic) IBOutlet UITextView *MessageView;
@property BOOL hasFinishedUploading;

@property (nonatomic, strong) AWSS3TransferManagerUploadRequest *uploadRequest;
@property (nonatomic, strong) NSURL * uploadVideoLocalURL;
@property (nonatomic, strong) MPMoviePlayerController * videoPlayer;
@property (nonatomic, strong) PFFile * thumbnailFile;

@end

@implementation VideoMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Video Message", @"Video message page title");
    UIBarButtonItem * sendButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", @"send text") style:UIBarButtonItemStylePlain target:self action:@selector(sendVideoMessage)];
    [sendButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:18.0]} forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = sendButtonItem;
    //self.BackgroundImageView.image = self.photo;
    self.MessageView.font = [UIFont fontWithName:@"OpenSans" size:15.0];
    self.MessageView.text = NSLocalizedString(@"Message ...", @"message placeholder");
    self.MessageView.delegate = self;
    [self.PlayVideoButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchDown];
    self.uploadVideoLocalURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"video%f.mp4",[[NSDate date]timeIntervalSince1970]]]];
    [self uploadVideo];
    
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
    if([self.MessageView.text isEqualToString:NSLocalizedString(@"Message ...", @"message placeholder")]){
        self.MessageView.text = @"";
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if(self.MessageView.text.length == 0){
        self.MessageView.text = NSLocalizedString(@"Message ...", @"message placeholder");
        self.MessageView.textColor = [UIColor colorWithRed:170/255.0 green:170/255.0 blue:170/255.0 alpha:1.0];
    }
}

#pragma mark - helper methods
- (void)uploadVideo{
    self.hasFinishedUploading = NO;
    self.PlayVideoButton.enabled = NO;
    self.BackgroundImageView.alpha = 0.3;
    self.VideoLoadingView.hidesWhenStopped = YES;
    [self.VideoLoadingView startAnimating];
    
    VideoMessageViewController __weak * weakSelf = self;
    // compression and upload video
    [self convertVideoToLowQuailtyWithInputURL:self.videoUrl handler:^(AVAssetExportSession * session) {
        if (session.status == AVAssetExportSessionStatusCompleted){
            // successful compress. Go ahead to upload the video.
            weakSelf.uploadRequest = [AWSS3TransferManagerUploadRequest new];
            weakSelf.uploadRequest.bucket = S3BucketName;
            weakSelf.uploadRequest.key = [weakSelf.uploadVideoLocalURL lastPathComponent];
            weakSelf.uploadRequest.body = weakSelf.uploadVideoLocalURL;
            [[[AWSS3TransferManager defaultS3TransferManager] upload:weakSelf.uploadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
                if (task.error != nil) {
                    [SVProgressHUD showErrorWithStatus:@"Failed to upload the video. Please try again."];
                }else {
                    self.hasFinishedUploading = YES;
                    self.PlayVideoButton.enabled = YES;
                    self.BackgroundImageView.alpha = 1.0;
                    [self.VideoLoadingView stopAnimating];
                    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:self.uploadVideoLocalURL];
                    UIImage * thumbnail = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
                    [player stop];
                    self.BackgroundImageView.image = thumbnail;
                    CGSize destinationSize = CGSizeMake(100, 150);
                    UIGraphicsBeginImageContext(destinationSize);
                    [thumbnail drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
                    UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    self.thumbnailFile = [PFFile fileWithName:@"thumb.jpg" data:UIImageJPEGRepresentation(thumbImage, 1)];
                    [self.thumbnailFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(succeeded){
                            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Successfully upload!", @"successful upload Alert")];
                            self.hasFinishedUploading = YES;
                            self.PlayVideoButton.enabled = YES;
                            self.BackgroundImageView.alpha = 1.0;
                        }else{
                            [SVProgressHUD showErrorWithStatus:NSLocalizedString( @"Failed to upload. Please try again.", @"upload photo error message")];
                            self.hasFinishedUploading = NO;
                            self.PlayVideoButton.enabled = NO;
                            self.BackgroundImageView.alpha = 0.8;
                        }
                        [self.VideoLoadingView stopAnimating];
                    }];
                }
                return nil;
            }];
        }
    }];
}

- (void)playVideo:(UIButton *)button{
    self.videoPlayer = [[MPMoviePlayerController alloc] initWithContentURL:self.uploadVideoLocalURL];
    self.videoPlayer.controlStyle = MPMovieControlStyleDefault;
    self.videoPlayer.shouldAutoplay = YES;
    [self.view addSubview:self.videoPlayer.view];
    [self.videoPlayer setFullscreen:YES animated:YES];
}

- (void)sendVideoMessage{
    [self.view endEditing:YES];
    if(!self.hasFinishedUploading){
        [SVProgressHUD showImage:[UIImage imageNamed:@"AlertIcon"] status:NSLocalizedString(@"Please wait to finish uploading the video.", @"")];
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
        newMessage.type = @"vd";
        newMessage.videoUrl = [self.uploadVideoLocalURL lastPathComponent];
        newMessage.messageImgThumb = self.thumbnailFile;
        VideoMessageViewController __weak * weakSelf = self;
        [newMessage saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(succeeded){
                NSDictionary *data = @{@"alert":newMessage.messageData, @"badge":@"Increment", @"title":NSLocalizedString(@"Silverline Companion", @"application name"), @"t": @"vd", @"pid":newMessage.objectId, @"n":[PFUser currentUser][@"name"], @"videoUrl":[self.uploadVideoLocalURL lastPathComponent], @"action":@"com.silverline.companion.UPDATE_STATUS"};
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

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL handler:(void (^)(AVAssetExportSession*))handler{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = self.uploadVideoLocalURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         handler(exportSession);
     }];
}


@end
