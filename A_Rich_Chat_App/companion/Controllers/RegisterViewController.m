//
//  RegisterViewController.m
//  companion
//
//  Created by qiyue song on 2/3/15.
//  Copyright (c) 2015 silverline. All rights reserved.
//

#import "RegisterViewController.h"
#import "StartViewController.h"

#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>

@interface RegisterViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *WelcomeToLabel;
@property (weak, nonatomic) IBOutlet UILabel *AppNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *ProfileButton;
@property (weak, nonatomic) IBOutlet UITextField *FirstNameField;
@property (weak, nonatomic) IBOutlet UITextField *LastNameField;
@property (weak, nonatomic) IBOutlet UITextField *EmailField;
@property (weak, nonatomic) IBOutlet UITextField *PasswordField;
@property (weak, nonatomic) IBOutlet UIButton *CreateAccountButton;

@property (assign) BOOL hasSetProfile;
@property (nonatomic, strong) PFFile * profileImageFile;

- (IBAction)onCreateAccountButtonPressed:(UIButton *)sender;
- (IBAction)onProfileButtonPressed:(UIButton *)sender;
@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Register", @"Register title");
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:gestureRecognizer];

    self.WelcomeToLabel.font = [UIFont fontWithName:@"OpenSans" size:20.0];
    self.AppNameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:26.0];
    self.EmailField.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.PasswordField.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.FirstNameField.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.LastNameField.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.CreateAccountButton.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:22.0];
    
    self.EmailField.delegate = self;
    self.PasswordField.delegate = self;
    self.FirstNameField.delegate = self;
    self.LastNameField.delegate = self;
    self.CreateAccountButton.enabled = NO;
    self.CreateAccountButton.alpha = 0.6;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 4;
}

#pragma mark - Text Field Delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSInteger firstNameLength = self.FirstNameField.text.length;
    NSInteger lastNameLength = self.LastNameField.text.length;
    NSInteger emailLength = self.EmailField.text.length;
    NSInteger passwordLength = self.PasswordField.text.length;
    if(self.hasSetProfile && textField.text.length - range.length + string.length > 0){
        if([textField isEqual:self.FirstNameField]){
            if(lastNameLength && emailLength && passwordLength){
                self.CreateAccountButton.enabled = YES;
                self.CreateAccountButton.alpha = 1;
            }else{
                self.CreateAccountButton.enabled = NO;
                self.CreateAccountButton.alpha = 0.6;
            }
        }else if([textField isEqual:self.LastNameField]){
            if(firstNameLength && emailLength && passwordLength){
                self.CreateAccountButton.enabled = YES;
                self.CreateAccountButton.alpha = 1;
            }else{
                self.CreateAccountButton.enabled = NO;
                self.CreateAccountButton.alpha = 0.6;
            }
        }else if([textField isEqual:self.EmailField]){
            if(lastNameLength && firstNameLength && passwordLength){
                self.CreateAccountButton.enabled = YES;
                self.CreateAccountButton.alpha = 1;
            }else{
                self.CreateAccountButton.enabled = NO;
                self.CreateAccountButton.alpha = 0.6;
            }
        }else{
            if(lastNameLength && emailLength && firstNameLength){
                self.CreateAccountButton.enabled = YES;
                self.CreateAccountButton.alpha = 1;
            }else{
                self.CreateAccountButton.enabled = NO;
                self.CreateAccountButton.alpha = 0.6;
            }
        }
    }else{
        self.CreateAccountButton.enabled = NO;
        self.CreateAccountButton.alpha = 0.6;
    }
    return YES;
}

#pragma mark - UIImagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    self.profileImageFile = [PFFile fileWithName:@"profile.jpg" data:imageData];
    RegisterViewController __weak * weakSelf = self;
    [self.profileImageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(succeeded){
            [weakSelf.ProfileButton setImage:image forState:UIControlStateNormal];
            weakSelf.hasSetProfile = YES;
            [weakSelf checkUserInputStatus];
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Upload successfully!", @"successful uploading message")];
        }else{
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to upload the profile image. Please try again.",@"upload error message")];
        }
    } progressBlock:^(int percentDone) {
        [SVProgressHUD showProgress:percentDone/100.0 status:NSLocalizedString(@"Uploading Profile Image ...", @"uploading message") maskType:SVProgressHUDMaskTypeGradient];
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - helper methods
- (void)dismissKeyboard{
    [self.view endEditing:YES];
}

- (IBAction)onCreateAccountButtonPressed:(UIButton *)sender {
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    PFUser * newUser = [PFUser user];
    newUser.username = self.EmailField.text;
    newUser.password = self.PasswordField.text;
    newUser.email = self.EmailField.text;
    newUser[@"firstName"] = self.FirstNameField.text;
    newUser[@"lastName"] = self.LastNameField.text;
    newUser[@"profileImage"] = self.profileImageFile.url;
    newUser[@"type"] = @"Companion";
    newUser[@"isActivated"] = @YES;
    [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(succeeded){
            [SVProgressHUD dismiss];
            UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            StartViewController * startVC = [storyboard instantiateViewControllerWithIdentifier:@"Start"];
            startVC.email = self.EmailField.text;
            [self presentViewController:startVC animated:YES completion:nil];
        }else{
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to create new account. Please try again.", @"sign up failed message")];
        }
    }];
}

- (IBAction)onProfileButtonPressed:(id)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)checkUserInputStatus{
    if(self.FirstNameField.text.length > 0 && self.LastNameField.text.length > 0 && self.EmailField.text.length > 0 && self.PasswordField.text.length > 0) {
        self.CreateAccountButton.enabled = YES;
        self.CreateAccountButton.alpha = 1;
    }else{
        self.CreateAccountButton.enabled = NO;
        self.CreateAccountButton.alpha = 0.6;
    }
}

@end
