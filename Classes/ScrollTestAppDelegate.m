//
//  ScrollTestAppDelegate.m
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-13.
//  Copyright Hippo Foundry 2010. All rights reserved.
//

#import "ScrollViewController.h"
#import "ScrollTestAppDelegate.h"


@implementation ScrollTestAppDelegate

@synthesize window, controller;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	ScrollViewController *scrollController = [[ScrollViewController alloc] init];
	
	controller = [[UINavigationController alloc] initWithRootViewController:scrollController];
	
	[window setBackgroundColor:[UIColor blackColor]];
	[window addSubview:controller.view];
    [window makeKeyAndVisible];
    
    return YES;
}

- (void)dealloc {
    [window release];
	[controller release];
    [super dealloc];
}

@end
