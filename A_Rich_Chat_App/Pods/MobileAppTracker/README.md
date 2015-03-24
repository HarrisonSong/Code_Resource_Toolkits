Installing MobileAppTracking iOS SDK using CocoaPods
=======

[CocoaPods: The Objective-C Library Manager](http://www.cocoapods.org) allows you to manage the library dependencies of your iOS Xcode project. 
You can use CocoaPods to install MobileAppTracking iOS SDK and required system frameworks.

## Steps to include MobileAppTracking (MAT) iOS SDK to your iOS Xcode project

### Install CocoaPods

If you have already installed CocoaPods then you can skip this step.

    $ [sudo] gem install cocoapods
    $ pod setup

### Install MobileAppTracker pod

Once CocoaPods has been installed, you can include MAT iOS SDK to your project by adding a dependency entry to the Podfile in your project root directory.

    $ edit Podfile
    platform :ios
    pod 'MobileAppTracker'

This sample shows a minimal Podfile that you can use to include MAT iOS SDK dependency to your project. You can include any other dependency as required by your project.

Now you can install the dependencies in your project:

    $ pod install
    
Once you install a pod dependency in your project, make sure to always open the Xcode workspace instead of the project file when building your project:

    $ open App.xcworkspace
    
Now you can import MobileAppTracker in your source files:

    #import <MobileAppTracker.h>
    
At this point MAT iOS SDK is ready for use in your project.


### Next Steps

Refer [MAT SDK Integration Document](http://support.mobileapptracking.com/entries/23745301-iOS-SDK-v2-6-1) for help on tracking installs and events using the MAT iOS SDK.
    


