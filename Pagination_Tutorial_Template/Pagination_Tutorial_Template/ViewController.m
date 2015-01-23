//
//  ViewController.m
//  Pagination_Tutorial_Template
//
//  Created by qiyue song on 23/1/15.
//  Copyright (c) 2015 qiyuesong. All rights reserved.
//

#import "ViewController.h"
#import "TourPageViewController.h"
#import "UIScreen+AspectRation.h"

@interface ViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *PageViewContainer;
@property (weak, nonatomic) IBOutlet UIPageControl *PageControl;
@property (nonatomic, strong) UIPageViewController * pageViewController;
@property (nonatomic, strong) NSArray * TourPagesList;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if([UIScreen mainScreen].aspectRatio == UIScreenAspectRatio16by9){
        self.TourPagesList = @[@"6_Experience", @"6_Companions", @"6_Contact", @"6_Learn", @"6_Location", @"6_Camera", @"6_Well Being", @"6_Emergency", @"6_Get_Started"];
    }else if([UIScreen mainScreen].aspectRatio == UIScreenAspectRatio3by2){
        self.TourPagesList = @[@"4_Experience", @"4_Companions", @"4_Contact", @"4_Learn", @"4_Location", @"4_Camera", @"4_Well Being", @"4_Emergency", @"4_Get_Started"];
    }
    
    // Create page view controller
    
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    [self.pageViewController setViewControllers:@[[self viewControllerAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    // Change the size of page view controller
    self.pageViewController.view.frame = CGRectMake(0, 0, self.PageViewContainer.frame.size.width, self.PageViewContainer.frame.size.height + 40.0);
    
    [self addChildViewController:self.pageViewController];
    [self.PageViewContainer insertSubview:self.pageViewController.view belowSubview:self.PageControl];
    self.PageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    self.PageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
    self.PageControl.backgroundColor = [UIColor clearColor];
    self.PageControl.hidden = NO;
    [self.pageViewController didMoveToParentViewController:self];
}

#pragma mark - Page View Data Source
- (TourPageViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{
    NSUInteger index = ((TourPageViewController *) viewController).pageIndex;
    if(index == 8 || index == NSNotFound){
        return nil;
    }
    index++;
    return [self viewControllerAtIndex:index];
}

- (TourPageViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    NSUInteger index = ((TourPageViewController *) viewController).pageIndex;
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    index--;
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return 9;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}

#pragma mark - UI Page View Delegate
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{
    if(completed){
        self.PageControl.currentPage = ((TourPageViewController *) pageViewController.viewControllers[0]).pageIndex;
    }
}

#pragma mark - helper methods
- (TourPageViewController *)viewControllerAtIndex:(NSUInteger)index
{
    TourPageViewController * pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TourPage"];
    pageContentViewController.imageFile = self.TourPagesList[index];
    pageContentViewController.pageIndex = index;
    if(index == 8){
        UIButton * Button = [[UIButton alloc] initWithFrame:pageContentViewController.view.frame];
        Button.titleLabel.text = @"";
        Button.backgroundColor = [UIColor clearColor];
        [Button addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [pageContentViewController.view addSubview:Button];
    }
    return pageContentViewController;
}

- (void)onButtonPressed:(UIButton *)sender{
    //TO DO: to be implemented
}

@end
