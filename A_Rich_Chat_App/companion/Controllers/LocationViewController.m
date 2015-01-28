//
//  LocationViewController.m
//  companion
//
//  Created by qiyue song on 28/11/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "LocationViewController.h"
#import <MapKit/MapKit.h>

#define UNIT 609.344

@interface LocationViewController ()

@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation LocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Location";
    self.mapView.mapType = MKMapTypeStandard;
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.location.latitude, self.location.longitude);
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance(coordinate, 0.5 * UNIT, 0.5 * UNIT);
    MKPointAnnotation * marker = [[MKPointAnnotation alloc] init];
    marker.coordinate = coordinate;
    [self.mapView addAnnotation:marker];
    [self.mapView setRegion:region animated:YES];
}

@end
