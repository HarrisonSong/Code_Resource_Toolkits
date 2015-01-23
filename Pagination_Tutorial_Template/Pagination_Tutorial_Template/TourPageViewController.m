//
//  TourPageViewController.m
//  Pagination_Tutorial_Template
//
//  Created by qiyue song on 23/1/15.
//  Copyright (c) 2015 qiyuesong. All rights reserved.
//

#import "TourPageViewController.h"

@interface TourPageViewController ()

@end

@implementation TourPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.TourImage.image = [UIImage imageNamed:self.imageFile];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
