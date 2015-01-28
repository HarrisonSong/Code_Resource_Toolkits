//
//  AlertsViewController.m
//  companion
//
//  Created by qiyue song on 10/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "AlertsViewController.h"
#import "AlertInbox.h"
#import "AlertCell.h"

@interface AlertsViewController ()

@property (nonatomic, strong) NSMutableArray * AlertsList;
@property (nonatomic, strong) UIRefreshControl * RfreshControl;

@end

@implementation AlertsViewController

- (NSMutableArray *)AlertsList{
    if(_AlertsList == nil) _AlertsList = [NSMutableArray new];
    return  _AlertsList;
}


- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadAlertsList) forControlEvents:UIControlEventValueChanged];
    [self.refreshControl beginRefreshing];
    [self reloadAlertsList];
    
    self.navigationItem.title = NSLocalizedString(@"System Alerts", @"Alert view title");
}


#pragma mark - UITableView Data Source
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.AlertsList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 90.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    AlertCell * cell = [tableView dequeueReusableCellWithIdentifier:@"AlertCell"];
    AlertInbox * currentAlert = self.AlertsList[indexPath.row];
    if (cell == nil) {
        // Load the top-level objects from the custom cell XIB.
        NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"AlertCell" owner:self options:nil];
        cell = objects[0];
    }
    cell.AlertContent.text = currentAlert.messageData;
    cell.AlertContent.font = [UIFont fontWithName:@"OpenSans" size:16.0];
    cell.AlertTime.text = [NSDateFormatter localizedStringFromDate:currentAlert.createdAt dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    cell.AlertTime.font = [UIFont fontWithName:@"OpenSans-Light" size:16.0];
    if(!currentAlert.isRead){
        cell.backgroundColor = [UIColor colorWithRed:203.0/255.0 green:210.0/255.0 blue:234.0/255.0 alpha:1];
    }
    return cell;
}

#pragma mark - UITableView Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.tableView cellForRowAtIndexPath:indexPath].backgroundColor = [UIColor whiteColor];
    AlertInbox * currentAlert = self.AlertsList[indexPath.row];
    if(!currentAlert.isRead){
        currentAlert.isRead = YES;
        [currentAlert saveInBackground];
    }
}


#pragma mark - helper methods
- (void)reloadAlertsList{
    PFQuery * alertsQuery = [AlertInbox query];
    [alertsQuery whereKey:@"userId" equalTo:[PFUser currentUser]];
    [alertsQuery whereKey:@"isRead" equalTo:@NO];
    [alertsQuery whereKey:@"type" equalTo:@"sys"];
    [alertsQuery orderByDescending:@"createdAt"];
    [alertsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error && objects.count > 0){
            [self.AlertsList removeAllObjects];
            [self.AlertsList addObjectsFromArray:objects];
            [self.tableView reloadData];
        }else{
            if(!error){
                NSLog(@"Failed to fetch alert message.");
            }else{
                NSLog(@"There is not alert message currently.");
                [self.tableView reloadData];
            }
        }
        [self.refreshControl endRefreshing];
    }];
}

@end
