//
//  Senior.m
//  companion
//
//  Created by qiyue song on 5/11/14.
//  Copyright (c) 2014 qiyuesong. All rights reserved.
//

#import "Senior.h"
#import <Parse/PFObject+Subclass.h>

@implementation Senior

@dynamic objectId;
@dynamic address;
@dynamic ageByYear;
@dynamic allergies;
@dynamic dataOfBirth;
@dynamic gender;
@dynamic identificationNumber;
@dynamic language;
@dynamic lastCheckedIn;
@dynamic location;
@dynamic name;
@dynamic phoneNumber;
@dynamic profileImage;
@dynamic userId;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return @"Senior";
}

- (Senior *)initByPFObject:(PFObject *)object withName:(NSString *)seniorName profileImage:(PFFile *)image{
    self = [super init];
    if(self){
        self.objectId = object.objectId;
        self.address = object[@"address"];
        self.ageByYear = object[@"ageByYear"];
        self.allergies = object[@"allergies"];
        self.dataOfBirth = object[@"dataOfBirth"];
        self.gender = [object[@"gender"] intValue];
        self.identificationNumber = object[@"identificationNumber"];
        self.language = object[@"language"];
        self.lastCheckedIn = object[@"lastCheckedIn"];
        self.location = object[@"location"];
        self.phoneNumber = object[@"phoneNumber"];
        self.userId = object[@"userId"];
        self.profileImage = image;
        self.name = seniorName;
    }
    return self;
}

- (void)updateByObject:(PFObject *)object{
    self.objectId = object.objectId;
    self.address = object[@"address"];
    self.ageByYear = object[@"ageByYear"];
    self.allergies = object[@"allergies"];
    self.dataOfBirth = object[@"dataOfBirth"];
    self.gender = [object[@"gender"] intValue];
    self.identificationNumber = object[@"identificationNumber"];
    self.language = object[@"language"];
    self.lastCheckedIn = object[@"lastCheckedIn"];
    self.location = object[@"location"];
    self.phoneNumber = object[@"phoneNumber"];
    self.userId = object[@"userId"];
}

@end
