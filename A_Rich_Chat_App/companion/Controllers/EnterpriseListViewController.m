//
//  EnterpriseListViewController.m
//  Silverline
//
//  Created by qiyue song on 10/2/15.
//  Copyright (c) 2015 Silverline. All rights reserved.
//

#import "EnterpriseListViewController.h"
#import "EnterpriseContentViewController.h"

@interface EnterpriseListViewController ()

@property (nonatomic, strong) NSMutableArray * enterpriseList;
@property (nonatomic, strong) UIRefreshControl * refreshControl;

@end

@implementation EnterpriseListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Enterprise List", @"Enterprise List title");
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadEnterpriseList) forControlEvents:UIControlEventValueChanged];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl beginRefreshing];
    [self reloadEnterpriseList];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.enterpriseList.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] init];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFUser * currentEnterprise = self.enterpriseList[indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EnterpriseCell" forIndexPath:indexPath];
    
    if(cell == nil){
        cell = [[NSBundle mainBundle] loadNibNamed:@"EnterpriseCell" owner:self options:nil][0];
    }
    
    PFFile * enterpriseProfileImageFile = currentEnterprise[@"profileicon"];
    
    ((UIActivityIndicatorView *)[cell viewWithTag:3]).hidesWhenStopped = YES;
    [((UIActivityIndicatorView *)[cell viewWithTag:3]) startAnimating];
    [enterpriseProfileImageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if(!error){
            ((UIImageView *)[cell viewWithTag:1]).image = [UIImage imageWithData:data];
        }else{
            NSLog(@"Failed to load the enterprise icon.");
        }
        [((UIActivityIndicatorView *)[cell viewWithTag:3]) stopAnimating];
    }];
    ((UILabel *)[cell viewWithTag:2]).text = currentEnterprise[@"name"];
    ((UILabel *)[cell viewWithTag:2]).font = [UIFont fontWithName:@"OpenSans" size:17.0];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EnterpriseContentViewController * enterpriseContentVC = [storyboard instantiateViewControllerWithIdentifier:@"EnterpriseContent"];
    enterpriseContentVC.enterprise = self.enterpriseList[indexPath.row];
    [self.navigationController pushViewController:enterpriseContentVC animated:YES];
}

#pragma mark - helper methods
- (void)reloadEnterpriseList{
    PFQuery * enterpriseQuery = [PFUser query];
    [enterpriseQuery whereKey:@"type" equalTo:@"enterprise"];
    [enterpriseQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error && objects.count > 0){
            self.enterpriseList = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
        }else{
            NSLog(@"No available enterpirse.");
        }
        [self.refreshControl endRefreshing];
    }];
}

@end
