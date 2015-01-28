//
//  AppDelegate.m
//  companion
//
//  Created by qiyue song on 17/11/14.
//  Copyright (c) 2014 silverline. All rights reserved.
//

#import "AppDelegate.h"
#import "shareItemManager.h"
#import "Credential.h"

#import <Parse/Parse.h>
#import <FacebookSDK/FacebookSDK.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import <HockeySDK/HockeySDK.h>

#import  <AWSiOSSDKv2/AWSCore.h>
#import <AWSiOSSDKv2/AWSCredentialsProvider.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

#define SYSTEM_VERSION_LESS_THAN(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Parse Setup
    NSString * developmentMode = ParseMode;
    if([developmentMode isEqualToString:@"Dev"]){
        [Parse setApplicationId:ParseDEVAppID clientKey:ParseDEVClientKey];
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:HockeyAppBetaId];
        [[BITHockeyManager sharedHockeyManager] setDebugLogEnabled: YES];
    }else if([developmentMode isEqualToString:@"v2"]){
        [Parse setApplicationId:ParseLiveAppID clientKey:ParseLiveClientKey];
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:HockeyAppLiveId];
        [[BITHockeyManager sharedHockeyManager] setDebugLogEnabled: NO];
    }

    [PFFacebookUtils initializeFacebook];
    
    // Facebook Setup
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    
    // AWS Setup
    if(!SYSTEM_VERSION_LESS_THAN(@"7.0")){
        AWSCognitoCredentialsProvider *credentialsProvider = [AWSCognitoCredentialsProvider credentialsWithRegionType:AWSRegionUSEast1 accountId:AWSAccountID identityPoolId:CognitoPoolID unauthRoleArn:CognitoRoleUnauth authRoleArn:CognitoRoleAuth];
        AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:AWSRegionAPSoutheast1 credentialsProvider:credentialsProvider];
        [[AWSServiceManager defaultServiceManager] setDefaultServiceConfiguration:configuration];
        [AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
    }
    NSLog(@"Registering for push notifications...");
    if(!SYSTEM_VERSION_LESS_THAN(@"8.0")){
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound |UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    }else{
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }
    
    //add updating badge number listener
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(onReceivingUpdateTabBarBadgeNotification:)
     name:@"updateTabBarBadgeNumber"
     object:nil];
        
    // Update the font for each UIBarButtonItem
    [[UIBarButtonItem appearance]
     setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans" size:16.0]}
     forState:UIControlStateNormal];
    
    // Update App Badge
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    PFInstallation * currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.badge = 0;
    [currentInstallation saveInBackground];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
    
    // Update App Badge
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    PFInstallation * currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.badge = 0;
    [currentInstallation saveInBackground];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[PFFacebookUtils session] close];
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current Installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    //register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"%s: failed to register for push notifications with error %@", __FUNCTION__, error.localizedDescription);
    if ([error code] == 3010) {
        NSLog(@"Push notifications don't work in the simulator!");
    } else {
        NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    //handle the actions
    if ([identifier isEqualToString:@"declineAction"]){
    }
    else if ([identifier isEqualToString:@"answerAction"]){
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    
    // Update App Badge
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    PFInstallation * currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.badge = 0;
    [currentInstallation saveInBackground];
    
    if([PFUser currentUser] && [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]){
        //Handle interactions
        NSString * type = userInfo[@"t"];
        if([type isEqualToString:@"as"]){
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"UIApplicationDidReceiveRemoteAsNotification"
             object:self
             userInfo:userInfo];
        }else if([type isEqualToString:@"ci"]){
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"UIApplicationDidReceiveRemoteCiNotification"
             object:self
             userInfo:userInfo];
        }else if([type isEqualToString:@"mr"] || [type isEqualToString:@"up"] || [type isEqualToString:@"tl"] || [type isEqualToString:@"wb"] || [type isEqualToString:@"wb"] || [type isEqualToString:@"em-call"] || [type isEqualToString:@"em-sensor"]){
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"UIApplicationDidReceiveRemoteMrNotification"
             object:self
             userInfo:userInfo];
        }
    }
}


#pragma mark - helper methods

- (void)onReceivingUpdateTabBarBadgeNotification:(NSNotification *)notif{
    [self updateTabBarBadgeNumber];
}

- (void)updateTabBarBadgeNumber{
    if([[shareItemManager sharedInstance].tabBarItemBadgeNumber isEqualToNumber:@0]){
        ((UITabBarItem *)((UITabBarController *)self.window.rootViewController).tabBar.items[1]).badgeValue = nil;
    }else{
        ((UITabBarItem *)((UITabBarController *)self.window.rootViewController).tabBar.items[1]).badgeValue = [NSString stringWithFormat:@"%@", [shareItemManager sharedInstance].tabBarItemBadgeNumber];
    }
}

@end

