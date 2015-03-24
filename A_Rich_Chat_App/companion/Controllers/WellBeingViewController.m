//
//  WellBeingViewController.m
//  companion
//
//  Created by qiyue song on 2/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "WellBeingViewController.h"
#import "GraphView.h"
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <PromiseKit/PromiseKit.h>

#define UNIT 609.344

@interface WellBeingViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lastCheckInTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastKnownLabel;
@property (weak, nonatomic) IBOutlet UILabel *wellBeingTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *exerciseStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *moodStatusLabel;

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *lastCheckInTime;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *lastKnownTime;
@property (weak, nonatomic) IBOutlet UILabel *lastLocation;
@property (weak, nonatomic) IBOutlet MKMapView *locationMap;
@property (weak, nonatomic) IBOutlet UILabel *homeStatus;
@property (weak, nonatomic) IBOutlet UILabel *WaterStatus;
@property (weak, nonatomic) IBOutlet UIImageView *ExerciseImage;
@property (weak, nonatomic) IBOutlet UIImageView *MoodImage;
@property (weak, nonatomic) IBOutlet UIView *Graph;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ExerciseIconWidthConstraint;

@property (nonatomic, strong) GraphView * historyGraph;
@property (nonatomic, strong) NSMutableArray * WaterHistory;
@property (nonatomic, strong) NSMutableArray * ExerciseHistory;
@property (nonatomic, strong) NSMutableArray * MoodHistory;

- (IBAction)onSegmentControlChanged:(UISegmentedControl *)sender;
@end

@implementation WellBeingViewController

- (NSMutableArray *)WaterHistory{
    if(_WaterHistory == nil) _WaterHistory = [NSMutableArray arrayWithArray:@[@0, @0, @0, @0, @0, @0, @0]];
    return  _WaterHistory;
}

- (NSMutableArray *)ExerciseHistory{
    if(_ExerciseHistory == nil) _ExerciseHistory = [NSMutableArray arrayWithArray:@[@1, @1, @1, @1, @1, @1, @1]];
    return  _ExerciseHistory;
}

- (NSMutableArray *)MoodHistory{
    if(_MoodHistory == nil) _MoodHistory = [NSMutableArray arrayWithArray:@[@3, @3, @3, @3, @3, @3, @3]];
    return  _MoodHistory;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Well Being", @"Well Being title");
    
    if(self.senior){
        self.locationMap.mapType = MKMapTypeStandard;
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(refreshAllStatus) forControlEvents:UIControlEventValueChanged];
        [self reloadAllStatus];
    }
    
    CGRect frame = self.Graph.frame;
    frame.origin = CGPointMake(0, 0);
    self.historyGraph = [[GraphView alloc] initWithFrame:frame];
    self.historyGraph.backgroundColor = [UIColor clearColor];
    self.historyGraph.type = WATER;
    [self.Graph addSubview:self.historyGraph];
    
    // Update text fonts
    self.name.font = [UIFont fontWithName:@"OpenSans-Extrabold" size:30.0];
    if(![[NSLocale preferredLanguages][0] isEqualToString:@"ms"]){
        self.lastCheckInTimeLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    }else{
        self.lastCheckInTimeLabel.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    }
    self.lastCheckInTime.font = [UIFont fontWithName:@"OpenSans" size:17.0];
    self.locationTitleLabel.font = [UIFont fontWithName:@"OpenSans-Extrabold" size:30.0];
    self.lastKnownLabel.font = [UIFont fontWithName:@"OpenSans" size:17.0];
    self.lastKnownTime.font = [UIFont fontWithName:@"OpenSans" size:17.0];
    self.lastLocation.font = [UIFont fontWithName:@"OpenSans-Light" size:20.0];
    self.wellBeingTitleLabel.font = [UIFont fontWithName:@"OpenSans-Extrabold" size:26.0];
    self.homeStatus.font = [UIFont fontWithName:@"OpenSans-Light" size:24.0];
    self.WaterStatus.font = [UIFont fontWithName:@"OpenSans-Light" size:20.0];
    self.exerciseStatusLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:24.0];
    self.moodStatusLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:24.0];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(didReceiveRemoteNotification:)
     name:@"UIApplicationDidReceiveRemoteCiNotification"
     object:nil];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:
            return 172;
        case 1:
            return 360;
        case 2:
            return 287;
        case 3:
            return 300;
        default:
            return 0;
    }
}

#pragma mark - helper methods
- (void)didReceiveRemoteNotification:(NSNotification *)notif{
    [self updateBasicInfo:^(BOOL succeed, NSError *error) {
        [SVProgressHUD dismiss];
    }];
}

- (void)refreshAllStatus{
    PFQuery * updatedQuery = [Senior query];
    [updatedQuery getObjectInBackgroundWithId:self.senior.objectId block:^(PFObject *object, NSError *error) {
        if(!error && object){
            [self.senior updateByObject:object];
            [self reloadAllStatus];
        }else{
            [self.refreshControl endRefreshing];
        }
    }];
}

- (void)reloadAllStatus{
    WellBeingViewController __weak * weakSelf = self;
    PMKPromise * updateBasicPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [weakSelf updateBasicInfo:^(BOOL succeed, NSError *error) {
            if(succeed){
                fulfill(@"successful");
            }else{
                reject(error);
            }
        }];
    }];
    PMKPromise * updateLastLocationPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [weakSelf updateLastLocation:^(BOOL succeed, NSError *error) {
            if(succeed){
                fulfill(@"successful");
            }else{
                reject(error);
            }
        }];
    }];
    PMKPromise * updateHomeStatusTodayPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [weakSelf updateHomeStatusToday:^(BOOL succeed, NSError *error) {
            if(succeed){
                fulfill(@"successful");
            }else{
                reject(error);
            }
        }];
    }];
    PMKPromise * updateWaterIntakeStatusPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [weakSelf updateWaterIntakeStatus:^(BOOL succeed, NSError *error) {
            if(succeed){
                fulfill(@"successful");
            }else{
                reject(error);
            }
        }];
    }];
    PMKPromise * updateExerciseStatusPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [weakSelf updateExerciseStatus:^(BOOL succeed, NSError *error) {
            if(succeed){
                fulfill(@"successful");
            }else{
                reject(error);
            }
        }];
    }];
    PMKPromise * updateMoodStatusPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject) {
        [weakSelf updateMoodStatus:^(BOOL succeed, NSError *error) {
            if(succeed){
                fulfill(@"successful");
            }else{
                reject(error);
            }
        }];
    }];
    [PMKPromise when:@[updateBasicPromise, updateLastLocationPromise, updateHomeStatusTodayPromise, updateWaterIntakeStatusPromise, updateExerciseStatusPromise, updateMoodStatusPromise]].then(^(NSArray *results){
    }).finally(^{
        [SVProgressHUD dismiss];
        [self.refreshControl endRefreshing];
    });
}

- (void)updateBasicInfo:(void(^)(BOOL succeed, NSError * error))completion{
    self.name.text = self.senior.name;
    self.lastCheckInTime.text = [NSDateFormatter localizedStringFromDate:self.senior.lastCheckedIn dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    [self.senior.profileImage getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if(!error && data){
            self.profileImage.image = [UIImage imageWithData:data];
            self.profileImage.clipsToBounds = YES;
            completion(YES, nil);
        }else{
            completion(NO, error);
        }
    }];
}

- (void)updateLastLocation:(void(^)(BOOL succeed, NSError * error))completion{
    PFQuery * lastLocationQuery = [PFQuery queryWithClassName:@"LastLocation"];
    [lastLocationQuery whereKey:@"userId" equalTo:self.senior.userId];
    [lastLocationQuery orderByDescending:@"updatedAt"];
    lastLocationQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [lastLocationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error && objects.count > 0){
            PFObject * lastLocation = objects[0];
            self.lastKnownTime.text = [NSDateFormatter localizedStringFromDate:lastLocation.updatedAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
            self.lastLocation.text = lastLocation[@"address"];
            PFGeoPoint * location = lastLocation[@"location"];
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude);
            [self.locationMap removeAnnotations:self.locationMap.annotations];
            MKCoordinateRegion region =
            MKCoordinateRegionMakeWithDistance(coordinate, 0.5 * UNIT, 0.5 * UNIT);
            MKPointAnnotation * marker = [[MKPointAnnotation alloc] init];
            marker.coordinate = coordinate;
            [self.locationMap addAnnotation:marker];
            [self.locationMap setRegion:region animated:YES];
            completion(YES, nil);
        }else{
            self.lastKnownTime.text = NSLocalizedString(@"Unknown", @"unknown message");
            self.lastLocation.text = NSLocalizedString(@"Unknown", @"unknown message");
            completion(NO, error);
        }
    }];
}

- (void)updateHomeStatusToday:(void(^)(BOOL succeed, NSError * error))completion{
    PFQuery * lastLocationQuery = [PFQuery queryWithClassName:@"LastLocation"];
    [lastLocationQuery whereKey:@"userId" equalTo:self.senior.userId];
    [lastLocationQuery orderByDescending:@"updatedAt"];
    [lastLocationQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error && objects.count > 0){
            PFObject * lastLocation = objects[0];
            double distance = [self.senior.location distanceInKilometersTo:lastLocation[@"location"]];
            if(distance > 0.015){
                self.homeStatus.text = NSLocalizedString(@"Out of Home", @"out of home stataus");
            }else{
                self.homeStatus.text = NSLocalizedString(@"In Home (within 100m)", @"in home status");
            }
        }else{
            self.homeStatus.text = NSLocalizedString(@"Out of Home", @"out of home stataus");
        }
        completion(YES, nil);
    }];
}

- (void)updateWaterIntakeStatus:(void(^)(BOOL succeed, NSError * error))completion{
    PFQuery * waterIntakeQuery = [PFQuery queryWithClassName:@"WaterIntake"];
    [waterIntakeQuery orderByAscending:@"createdAt"];
    [waterIntakeQuery whereKey:@"userId" equalTo:self.senior.userId];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSUInteger preservedComponents = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit);
    NSDate * todayMidNight = [calendar dateFromComponents:[calendar components:preservedComponents fromDate:[NSDate date]]];
    NSDate *tomorrowMidNight = [todayMidNight dateByAddingTimeInterval:60*60*24];
    [waterIntakeQuery whereKey:@"createdAt" greaterThanOrEqualTo:[tomorrowMidNight dateByAddingTimeInterval:-60 * 60 * 24 * 7]];
    [waterIntakeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error){
            if(objects.count > 0){
                NSDate * tonight = tomorrowMidNight;
                NSDate * morning = [tomorrowMidNight dateByAddingTimeInterval:-60*60*24];
                for(int i = 0; i < 7; i ++){
                    for(PFObject * waterIntake in objects){
                        if([waterIntake.createdAt compare:morning] == NSOrderedDescending && [waterIntake.createdAt compare:tonight] == NSOrderedAscending){
                            self.WaterHistory[i] = waterIntake[@"count"];
                        }
                    }
                    morning = [morning dateByAddingTimeInterval:-60*60*24];
                    tonight = [tonight dateByAddingTimeInterval:-60*60*24];
                }
            }
            self.WaterStatus.text = [NSString stringWithFormat:NSLocalizedString(@"X %@ Water intake for Today", @"today waterintake status"), self.WaterHistory[0]];
            completion(YES, nil);
        
            self.historyGraph.values = self.WaterHistory;
            self.historyGraph.axisImage = @"WaterAxis";
            [self.historyGraph setNeedsDisplay];
        }else{
            self.WaterStatus.text = [NSString stringWithFormat:NSLocalizedString(@"X %@ Water intake for Today", @"today waterintake status"), self.WaterHistory[0]];
            completion(NO, error);
        }
    }];
}

- (void)updateExerciseStatus:(void(^)(BOOL succeed, NSError * error))completion{
    PFQuery * exerciseQuery = [PFQuery queryWithClassName:@"Exercise"];
    [exerciseQuery orderByAscending:@"createdAt"];
    [exerciseQuery whereKey:@"userId" equalTo:self.senior.userId];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSUInteger preservedComponents = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit);
    NSDate * todayMidNight = [calendar dateFromComponents:[calendar components:preservedComponents fromDate:[NSDate date]]];
    NSDate *tomorrowMidNight = [todayMidNight dateByAddingTimeInterval:60*60*24];
    [exerciseQuery whereKey:@"createdAt" greaterThanOrEqualTo:[tomorrowMidNight dateByAddingTimeInterval:-60 * 60 * 24 * 7]];
    [exerciseQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error){
            if(objects.count > 0){
                NSDate * tonight = tomorrowMidNight;
                NSDate * morning = [tomorrowMidNight dateByAddingTimeInterval:-60*60*24];
                for(int i = 0; i < 7; i ++){
                    for(PFObject * exercise in objects){
                        if([exercise.createdAt compare:morning] == NSOrderedDescending && [exercise.createdAt compare:tonight] == NSOrderedAscending){
                            self.ExerciseHistory[i] = exercise[@"activity"];
                        }
                    }
                    morning = [morning dateByAddingTimeInterval:-60*60*24];
                    tonight = [tonight dateByAddingTimeInterval:-60*60*24];
                }
            }
            if([self.ExerciseHistory[0] isEqualToNumber:@1]){
                self.ExerciseImage.image = [UIImage imageNamed:@"ExerciseFatIcon"];
            }else{
                self.ExerciseImage.image = [UIImage imageNamed:@"ExerciseThinIcon"];
                self.ExerciseIconWidthConstraint.constant = 52;
            }
            completion(YES, nil);
        }else{
            if([self.ExerciseHistory[0] isEqualToNumber:@1]){
                self.ExerciseImage.image = [UIImage imageNamed:@"ExerciseFatIcon"];
            }else{
                self.ExerciseImage.image = [UIImage imageNamed:@"ExerciseThinIcon"];
                self.ExerciseIconWidthConstraint.constant = 52;
            }
            completion(NO, error);
        }
        
    }];
}

- (void)updateMoodStatus:(void(^)(BOOL succeed, NSError * error))completion{
    PFQuery * moodQuery = [PFQuery queryWithClassName:@"Mood"];
    [moodQuery orderByAscending:@"createdAt"];
    [moodQuery whereKey:@"userId" equalTo:self.senior.userId];
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSUInteger preservedComponents = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit);
    NSDate * todayMidNight = [calendar dateFromComponents:[calendar components:preservedComponents fromDate:[NSDate date]]];
    NSDate *tomorrowMidNight = [todayMidNight dateByAddingTimeInterval:60*60*24];
    [moodQuery whereKey:@"createdAt" greaterThanOrEqualTo:[tomorrowMidNight dateByAddingTimeInterval:-60 * 60 * 24 * 7]];
    [moodQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error){
            if(objects.count > 0){
                NSDate * tonight = tomorrowMidNight;
                NSDate * morning = [tomorrowMidNight dateByAddingTimeInterval:-60*60*24];
                for(int i = 0; i < 7; i ++){
                    for(PFObject * mood in objects){
                        if([mood.createdAt compare:morning] == NSOrderedDescending && [mood.createdAt compare:tonight] == NSOrderedAscending){
                            self.MoodHistory[i] = mood[@"mood"];
                        }
                    }
                    morning = [morning dateByAddingTimeInterval:-60*60*24];
                    tonight = [tonight dateByAddingTimeInterval:-60*60*24];
                }
            }
            if([self.MoodHistory[0] isEqualToNumber:@3]){
                self.MoodImage.image = [UIImage imageNamed:@"MoodLowIcon"];
            }else if([self.MoodHistory[0] isEqualToNumber:@4]){
                self.MoodImage.image = [UIImage imageNamed:@"MoodNormalIcon"];
            }else{
                self.MoodImage.image = [UIImage imageNamed:@"MoodHighIcon"];
            }
            completion(YES, nil);
        }else{
            if([self.MoodHistory[0] isEqualToNumber:@3]){
                self.MoodImage.image = [UIImage imageNamed:@"MoodLowIcon"];
            }else if([self.MoodHistory[0] isEqualToNumber:@4]){
                self.MoodImage.image = [UIImage imageNamed:@"MoodNormalIcon"];
            }else{
                self.MoodImage.image = [UIImage imageNamed:@"MoodHighIcon"];
            }
            completion(NO, error);
        }
    }];
}

- (IBAction)onSegmentControlChanged:(UISegmentedControl *)sender {
    NSMutableArray * history = nil;
    NSString * axisImage = nil;
    GraphType type = WATER;
    switch (sender.selectedSegmentIndex) {
        case 0:
        {
            history = self.WaterHistory;
            axisImage = @"WaterAxis";
            type = WATER;
            break;
        }
        case 1:
        {
            history = self.ExerciseHistory;
            axisImage = @"ExerciseAxis";
            type = EXERCISE;
            break;
        }
        case 2:
        {
            history = self.MoodHistory;
            axisImage = @"MoodAxis";
            type = MOOD;
            break;
        }
        default:{
            history = self.WaterHistory;
            axisImage = @"WaterAxis";
            type = WATER;
            break;
        }
    }
    self.historyGraph.values = history;
    self.historyGraph.axisImage = axisImage;
    self.historyGraph.type = type;
    [[self.historyGraph subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.historyGraph setNeedsDisplay];
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
