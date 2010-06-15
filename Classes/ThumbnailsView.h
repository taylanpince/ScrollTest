//
//  ThumbnailsView.h
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//


@protocol ThumbnailsViewDelegate;

@interface ThumbnailsView : UIView {
	NSArray *thumbnails;
	NSInteger selectedThumbIndex;
	
	id <ThumbnailsViewDelegate> delegate;
}

@property (nonatomic, retain) NSArray *thumbnails;

@property (nonatomic, assign) id <ThumbnailsViewDelegate> delegate;

- (void)selectThumb:(int)thumbIndex;

@end


@protocol ThumbnailsViewDelegate
- (void)didTapOnThumbnailWithIndex:(int)thumbIndex;
@end