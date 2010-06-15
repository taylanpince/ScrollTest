//
//  ThumbnailsView.m
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ThumbnailsView.h"


@interface ThumbnailsView (PrivateMethods)
- (void)didTapOnThumbnail:(id)sender;
- (void)didPanOverThumbnails:(id)sender;
@end


static NSUInteger PHOTO_WIDTH = 20.0;
static NSUInteger PHOTO_HEIGHT = 14.0;


@implementation ThumbnailsView

@synthesize thumbnails, delegate;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		[self setBackgroundColor:[UIColor clearColor]];
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnThumbnail:)];
		UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanOverThumbnails:)];
		
		[self addGestureRecognizer:panGesture];
		[self addGestureRecognizer:tapGesture];
		
		[panGesture release];
		[tapGesture release];
		
		selectedThumbIndex = 0;
    }
	
    return self;
}

- (void)selectThumb:(int)thumbIndex {
	if (selectedThumbIndex != thumbIndex) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.15];
		
		UIView *oldView = [self viewWithTag:selectedThumbIndex];
		UIView *newView = [self viewWithTag:thumbIndex];

		CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1.5, 1.5);
		
		oldView.transform = CGAffineTransformIdentity;
		newView.transform = scaleTransform;
		
		[UIView commitAnimations];

		[self bringSubviewToFront:newView];
		
		selectedThumbIndex = thumbIndex;
	}
}

- (void)didPanOverThumbnails:(id)sender {
	CGPoint touchPoint = [(UIPanGestureRecognizer *)sender locationInView:self];
	UIView *tappedView = [self hitTest:touchPoint withEvent:nil];
	
	if (tappedView != nil && tappedView != self) {
		[self selectThumb:tappedView.tag];
		[delegate didTapOnThumbnailWithIndex:tappedView.tag - 1];
	}
}

- (void)didTapOnThumbnail:(id)sender {
	CGPoint touchPoint = [(UITapGestureRecognizer *)sender locationInView:self];
	UIView *tappedView = [self hitTest:touchPoint withEvent:nil];
	
	if (tappedView != nil && tappedView != self) {
		[self selectThumb:tappedView.tag];
		[delegate didTapOnThumbnailWithIndex:tappedView.tag - 1];
	}
}

- (void)setThumbnails:(NSArray *)thumbnailsList {
	[thumbnails release];
	
	thumbnails = [thumbnailsList retain];
	
	int count = 1;

	for (NSString *thumb in thumbnails) {
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[thumb lastPathComponent]]];
		
		[imageView setFrame:CGRectMake(0.0, 0.0, PHOTO_WIDTH, PHOTO_HEIGHT)];
		[imageView setUserInteractionEnabled:YES];
		[imageView setContentMode:UIViewContentModeScaleAspectFit];
		[imageView setBackgroundColor:[UIColor blackColor]];
		[imageView setClipsToBounds:YES];
		[imageView setTag:count];
		
		imageView.layer.borderColor = [[UIColor whiteColor] CGColor];
		imageView.layer.borderWidth = 1.0;
		
		[self addSubview:imageView];
		
		[imageView release];
		
		count++;
	}
	
	[self setNeedsLayout];
	[self selectThumb:1];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	NSUInteger nextPhoto = 0;
	NSUInteger visiblePhotos = 0;
	NSUInteger totalPhotos = MIN(floorf(self.frame.size.width / (PHOTO_WIDTH + 1.0)), [thumbnails count]);
	NSUInteger skipAmount = MAX(ceilf((float) [[self subviews] count] / (float) totalPhotos), 1);

	if (totalPhotos * skipAmount > [thumbnails count]) {
		totalPhotos -= floorf(((totalPhotos * skipAmount) - [thumbnails count]) / skipAmount);
	}
	
	CGFloat leftOffset = (((PHOTO_WIDTH + 1.0) * totalPhotos) < self.frame.size.width) ? floorf((self.frame.size.width - ((PHOTO_WIDTH + 1.0) * totalPhotos)) / 2) : 0.0;

	for (NSUInteger photoCount = 0; photoCount < [thumbnails count]; photoCount++) {
		UIView *subView = [self viewWithTag:photoCount + 1];
		
		if (nextPhoto == photoCount) {
			[subView setHidden:NO];
			[subView setCenter:CGPointMake(leftOffset + (PHOTO_WIDTH / 2), 16.0 + (PHOTO_HEIGHT / 2))];
			
			leftOffset += PHOTO_WIDTH + 1.0;
			nextPhoto += skipAmount;
			visiblePhotos++;
		} else {
			[subView setHidden:YES];
		}
	}
}

- (void)dealloc {
	[thumbnails release];
    [super dealloc];
}

@end
