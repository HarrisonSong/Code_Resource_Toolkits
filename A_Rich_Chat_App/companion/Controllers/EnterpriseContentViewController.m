//
//  EnterpriseContentViewController.m
//  Silverline
//
//  Created by qiyue song on 10/2/15.
//  Copyright (c) 2015 Silverline. All rights reserved.
//

#import "EnterpriseContentViewController.h"

@interface EnterpriseContentViewController ()

@property (nonatomic, strong) NSMutableArray * offerList;
@property (nonatomic, strong) UIRefreshControl * refreshControl;

@end

@implementation EnterpriseContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Content", @"Enterprise Content title");
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadOfferList) forControlEvents:UIControlEventValueChanged];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl beginRefreshing];
    [self reloadOfferList];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.offerList.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject * currentOffer = self.offerList[indexPath.row];
    CGSize constraint = CGSizeMake(self.view.frame.size.width - 32.0f, 20000.0f);
    CGSize size = [currentOffer[@"desc"] sizeWithFont:[UIFont fontWithName:@"OpenSans-bold" size:17.0f] constrainedToSize:constraint lineBreakMode:NSLineBreakByTruncatingTail];
    if(currentOffer[@"image"]){
        return size.height * 1.1 + 180;
    }else{
        return size.height * 1.1 + 40;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject * currentOffer = self.offerList[indexPath.row];
    if([currentOffer[@"type"] isEqualToString:@"image"]){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EnterprisePhotoCell" forIndexPath:indexPath];
        
        if(cell == nil){
            cell = [[NSBundle mainBundle] loadNibNamed:@"EnterprisePhotoCell" owner:self options:nil][0];
        }
        
        [cell viewWithTag:1].layer.cornerRadius = 5;
        
        if(currentOffer[@"image"]){
            PFFile * imageFile = currentOffer[@"image"];
            [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if(!error){
                    ((UIImageView *)[cell viewWithTag:2]).image = [UIImage imageWithData:data];
                }else{
                    NSLog(@"Failed to download the image.");
                }
            }];
        }else{
            [[cell viewWithTag:2] removeFromSuperview];
        }
        
        ((UILabel *)[cell viewWithTag:3]).text = currentOffer[@"desc"];
        ((UILabel *)[cell viewWithTag:3]).font = [UIFont fontWithName:@"OpenSans-bold" size:17.0];
        return cell;
    }else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EnterpriseVideoCell" forIndexPath:indexPath];
        
        if(cell == nil){
            cell = [[NSBundle mainBundle] loadNibNamed:@"EnterpriseVideoCell" owner:self options:nil][0];
        }
        
        return cell;
    }
}

#pragma mark - helper methods
- (void)reloadOfferList{
    PFQuery * query = [PFQuery queryWithClassName:@"Offers"];
    [query whereKey:@"companion" equalTo:@YES];
    [query whereKey:@"user" equalTo:self.enterprise];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [self.refreshControl endRefreshing];
        if(!error && objects.count > 0){
            self.offerList = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
        }else{
            NSLog(@"Not Offer has been retrieved.");
        }
    }];
}

@end
