//
//  ThumbnailsView.h
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import "ImageRequest.h"


@protocol ThumbnailsViewDelegate;

@interface ThumbnailsView : UIView <ImageRequestDelegate> {
	NSArray *thumbnails;
	NSInteger selectedThumbIndex;
	
	ImageRequest *thumbRequest;
	
	id <ThumbnailsViewDelegate> delegate;
}

@property (nonatomic, retain) NSArray *thumbnails;

@property (nonatomic, retain) ImageRequest *thumbRequest;

@property (nonatomic, assign) id <ThumbnailsViewDelegate> delegate;

- (void)selectThumb:(int)thumbIndex;
- (UIImage *)thumbForIndex:(int)thumbIndex;

@end


@protocol ThumbnailsViewDelegate
- (void)didTapOnThumbnailWithIndex:(int)thumbIndex;
@end