//
//  Senior.h
//  companion
//
//  Created by qiyue song on 5/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import <Parse/Parse.h>

@interface Senior : PFObject <PFSubclassing>

@property (nonatomic, strong) NSString * address;
@property (nonatomic, strong) NSString * ageByYear;
@property (nonatomic, strong) NSString * allergies;
@property (nonatomic, strong) NSDate * dataOfBirth;
@property int gender;
@property (nonatomic, strong) NSString * identificationNumber;
@property (nonatomic, strong) NSString * language;
@property (nonatomic, strong) NSDate * lastCheckedIn;
@property (nonatomic, strong) PFGeoPoint * location;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * phoneNumber;
@property (nonatomic, strong) PFFile * profileImage;
@property (nonatomic, strong) PFUser * userId;

+ (NSString *)parseClassName;
- (Senior *)initByPFObject:(PFObject *)object withName:(NSString *)name profileImage:(PFFile *)image;
- (void)updateByObject:(PFObject *)object;

@end
