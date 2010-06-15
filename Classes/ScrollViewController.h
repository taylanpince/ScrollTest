//
//  ScrollViewController.h
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import "ScrollView.h"
#import "ImageRequest.h"
#import "ThumbnailsView.h"


@interface ScrollViewController : UIViewController <UIScrollViewDelegate, ScrollViewDataSource, ThumbnailsViewDelegate, ImageRequestDelegate> {
	ScrollView *scrollView;
	ThumbnailsView *thumbsView;
	
	NSArray *photos;
	NSMutableArray *imageRequests;
	NSUInteger activePhotoIndex;
}

@property (nonatomic, retain) ScrollView *scrollView;
@property (nonatomic, retain) ThumbnailsView *thumbsView;

@property (nonatomic, readonly) NSArray *photos;
@property (nonatomic, retain) NSMutableArray *imageRequests;

@end
