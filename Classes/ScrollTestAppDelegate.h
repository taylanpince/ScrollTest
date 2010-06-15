//
//  ScrollTestAppDelegate.h
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-13.
//  Copyright Hippo Foundry 2010. All rights reserved.
//


@interface ScrollTestAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UINavigationController *controller;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *controller;

@end

