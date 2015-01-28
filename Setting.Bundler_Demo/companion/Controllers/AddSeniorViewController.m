//
//  AddSeniorViewController.m
//  companion
//
//  Created by qiyue song on 18/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "AddSeniorViewController.h"
#import "LoginViewController.h"
#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

@interface AddSeniorViewController () <UIGestureRecognizerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *AddUserTitle;
@property (weak, nonatomic) IBOutlet UITextField *CountryCodeField;
@property (weak, nonatomic) IBOutlet UITextField *MobileNoField;
@property (weak, nonatomic) IBOutlet UITextField *NameField;
@property (weak, nonatomic) IBOutlet UIButton *AddSeniorButton;
@property (weak, nonatomic) IBOutlet UIButton *ProfileButton;
@property (weak, nonatomic) IBOutlet UIButton *CancelButton;
@property (assign) BOOL hasSetProfile;
@property (nonatomic, strong) PFFile * profileImageFile;

@property (nonatomic, strong) NSString * countryDialingCode;
@property (nonatomic, strong) NSMutableDictionary * codeDictionary;
@property (nonatomic, strong) NSArray * countryCodes;
@property (nonatomic, strong) NSDictionary * dialingCodeDictionary;
@property (nonatomic, strong) NSArray * nameArray;

- (IBAction)onProfileButtonPressed:(id)sender;
- (IBAction)AddSeniorButtonPressed:(id)sender;
- (IBAction)CancelButtonPressed:(id)sender;

@end

@implementation AddSeniorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    self.AddUserTitle.font = [UIFont fontWithName:@"OpenSans-Light" size:40.0];
    self.CountryCodeField.font = [UIFont fontWithName:@"OpenSans" size:20.0];
    self.MobileNoField.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.NameField.font = [UIFont fontWithName:@"OpenSans" size:18.0];
    self.AddSeniorButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:20.0];
    self.CancelButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:20.0];
    
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.backgroundColor = [UIColor whiteColor];
    picker.dataSource = self;
    picker.delegate = self;
    self.CountryCodeField.inputView = picker;
    
    NSString * dialingCodePlistPath = [[NSBundle mainBundle] pathForResource:@"DiallingCodes" ofType:@"plist"];
    self.dialingCodeDictionary = [NSDictionary dictionaryWithContentsOfFile:dialingCodePlistPath];
    CTTelephonyNetworkInfo *myNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier * myCarrier = [myNetworkInfo subscriberCellularProvider];
    NSString *countryCode = [myCarrier.isoCountryCode lowercaseString];
    self.CountryCodeField.text = @"+65";
    self.countryDialingCode = @"65";
    for(NSString * dialingCode in self.dialingCodeDictionary.allKeys){
        if([dialingCode isEqualToString:countryCode]){
            self.CountryCodeField.text = [NSString stringWithFormat:@"+%@",self.dialingCodeDictionary[dialingCode]];
            self.countryDialingCode = [NSString stringWithFormat:@"%@",self.dialingCodeDictionary[dialingCode]];
        }
    }
    
    // load nameDictionary
    NSString * namePlistPath = [[NSBundle mainBundle] pathForResource:@"CountrySpecificData" ofType:@"plist"];
    self.nameArray = [NSArray arrayWithContentsOfFile:namePlistPath];
    
    self.codeDictionary = [NSMutableDictionary dictionary];
    for(NSDictionary * countryDetails in self.nameArray){
        NSString * ISOCountryCode = ((NSString *)countryDetails[@"ISOCountryCode"]).lowercaseString;
        if([self.dialingCodeDictionary.allKeys containsObject:ISOCountryCode]){
            NSMutableDictionary * countryCodeInfo = [NSMutableDictionary dictionaryWithDictionary:@{@"DialingCode":self.dialingCodeDictionary[ISOCountryCode],@"CountryName":countryDetails[@"CountryName"],@"row":@(-1)}];
            [self.codeDictionary setObject:countryCodeInfo forKey:ISOCountryCode];
        }
    }
    self.countryCodes = [self.codeDictionary allKeys];
    self.countryCodes = [[self.countryCodes mutableCopy] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [picker reloadAllComponents];
    for(int i = 0; i < self.countryCodes.count; i++){
        self.codeDictionary[self.countryCodes[i]][@"row"]= @(i);
    }
    
    if([self.codeDictionary.allKeys containsObject:countryCode]){
        [picker selectRow:[self.codeDictionary[countryCode][@"row"] integerValue] inComponent:0 animated:NO];
    }
    
    // Do any additional setup after loading the view.
    [self.MobileNoField becomeFirstResponder];
    self.MobileNoField.delegate = self;
    self.NameField.delegate = self;
    [self.MobileNoField addTarget:self
                           action:@selector(textFieldDidChange:)
                 forControlEvents:UIControlEventEditingChanged];
    [self.NameField addTarget:self
                       action:@selector(textFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
    self.AddSeniorButton.enabled = NO;
    self.AddSeniorButton.alpha = 0.6;
}

- (IBAction)onProfileButtonPressed:(id)sender {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerController.delegate = self;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (IBAction)AddSeniorButtonPressed:(id)sender {
    NSString * phoneNumber = [NSString stringWithFormat:@"+%@%@",self.countryDialingCode, self.MobileNoField.text];
    PFQuery * SeniorQuery = [PFQuery queryWithClassName:@"Senior"];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
    [SeniorQuery whereKey:@"phoneNumber" equalTo:phoneNumber];
    AddSeniorViewController __weak * weakSelf = self;
    [SeniorQuery findObjectsInBackgroundWithBlock:^(NSArray * users, NSError *error) {
        if(!error && users.count > 0){
            // The targeting user exists. Proceed.
            PFQuery * SeniorUserQuery = [PFQuery queryWithClassName:@"SeniorUsers"];
            [SeniorUserQuery whereKey:@"senior" equalTo:users[0]];
            [SeniorUserQuery whereKey:@"user" equalTo:[PFUser currentUser]];
            [SeniorUserQuery findObjectsInBackgroundWithBlock:^(NSArray * SeniorUserObjects, NSError *error) {
                if(!error && SeniorUserObjects.count == 0){
                    //No Existed pair. Proceed.
                    PFObject * pendingSenior = [PFObject objectWithClassName:@"PendingSenior"];
                    pendingSenior[@"parent"] = [PFUser currentUser];
                    pendingSenior[@"profileImage"] = weakSelf.profileImageFile;
                    pendingSenior[@"name"] = weakSelf.NameField.text;
                    pendingSenior[@"phoneNumber"] = phoneNumber;
                    pendingSenior[@"relationship"] = @"TempRelation";
                    [pendingSenior saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(succeeded){
                            // Proceed to send notification to senior
                            NSDictionary *data = @{@"alert":[NSString stringWithFormat:NSLocalizedString(@"%@ has sent a pairing request to you.", @"has sent a pairing request to you."), [PFUser currentUser][@"name"]], @"badge":@"Increment", @"cuserid":[PFUser currentUser].objectId, @"sphoneno":phoneNumber, @"sid":pendingSenior.objectId, @"title":NSLocalizedString(@"Silverline Companion", @"application name"), @"action":@"com.silverline.companion.UPDATE_STATUS"};
                            PFPush *push = [[PFPush alloc] init];
                            [push setData:data];
                            PFQuery *pushQuery = [PFInstallation query];
                            [pushQuery whereKey:@"owner" equalTo:((PFObject *)users[0]).objectId];
                            [push setQuery:pushQuery];
                            [push sendPushInBackground];
                            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Your request has been sent to the member.", @"add senior request successfully send message")];
                            double delayInSeconds = 2.7;
                            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                //code to be executed on the main queue after delay
                                [weakSelf dismissViewControllerAnimated:YES completion:nil];
                            });
                        }else{
                            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to save the input data. please try again.", @"pendingSenior save error message")];
                        }
                    }];
                }else{
                    if(error){
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to check your pairing status. Please try again.", @"SeniorUser query error message")];
                    }else{
                        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"You have already paired with this member!",@"Senior already added message")];
                    }
                }
            }];
        }else{
            if(error){
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Failed to check member data. Please try again.", @"Senior query error message")];
            }else{
                // The targeting user does not exist. Warn.
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"The specific member has not been verified yet.",@"Senior not verified message")];
            }
        }
    }];
}

- (IBAction)CancelButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableView Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:
        {
            return 277.0;
        }
        case 1:
        {
            return 120.0;
        }
        case 2:
        {
            return 120.0;
        }
        default:
            return 20.0;
            break;
    }
}

#pragma mark - gestureRecognizer delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIButton class]]){
        return NO;
    }
    return YES;
}

#pragma mark - UITextField delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([textField isEqual:self.MobileNoField]){
        [self.NameField becomeFirstResponder];
    }else{
        [self.NameField resignFirstResponder];
    }
    return YES;
}

#pragma mark - UIImagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
    PFFile *imageFile = [PFFile fileWithName:@"profile.jpg" data:imageData];
    AddSeniorViewController __weak * weakSelf = self;
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(succeeded){
            [weakSelf.ProfileButton setBackgroundImage:image forState:UIControlStateNormal];
            weakSelf.hasSetProfile = YES;
            weakSelf.profileImageFile = imageFile;
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

#pragma mark - UI PickerView DataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    return 50.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return self.codeDictionary.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return  [NSString stringWithFormat:@"(%@) %@",self.codeDictionary[self.countryCodes[row]][@"DialingCode"], self.codeDictionary[self.countryCodes[row]][@"CountryName"]];
}

#pragma mark - UI PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.CountryCodeField.text = [NSString stringWithFormat:@"+%@", self.codeDictionary[self.countryCodes[row]][@"DialingCode"]];
    self.countryDialingCode = [NSString stringWithFormat:@"%@", self.codeDictionary[self.countryCodes[row]][@"DialingCode"]];
    [self.CountryCodeField resignFirstResponder];
}

#pragma mark - helper methods
- (void)dismissKeyboard{
    [self.view endEditing:YES];
}

- (void)textFieldDidChange:(UITextField *)textField{
    [self checkUserInputStatus];
}

- (void)checkUserInputStatus{
    if(self.hasSetProfile && self.MobileNoField.text.length > 0 && self.NameField.text.length > 0) {
        self.AddSeniorButton.enabled = YES;
        self.AddSeniorButton.alpha = 1;
    }else{
        self.AddSeniorButton.enabled = NO;
        self.AddSeniorButton.alpha = 0.6;
    }
}

@end
