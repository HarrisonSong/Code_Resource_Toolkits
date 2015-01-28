//
//  WebViewController.m
//  companion
//
//  Created by qiyue song on 9/12/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *LoadingView;
@property (weak, nonatomic) IBOutlet UIWebView * WebView;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = NO;
    
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:self.url]];
    [self.WebView loadRequest:requestObj];
    self.WebView.delegate = self;
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:20.0]}];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:YES];
    [self.LoadingView stopAnimating];
}

# pragma mark - UI WebView Delegate
- (void)webViewDidStartLoad:(UIWebView *)webView{
    self.LoadingView.hidesWhenStopped = YES;
    [self.LoadingView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    [self.LoadingView stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [self.LoadingView stopAnimating];
    NSLog(@"Failed to load the page.");
}

@end
