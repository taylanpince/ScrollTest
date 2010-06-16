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
- (void)getThumbForIndex:(int)thumbIndex;
@end


static NSUInteger const PHOTO_WIDTH = 20.0;
static NSUInteger const PHOTO_HEIGHT = 14.0;


@implementation ThumbnailsView

@synthesize thumbnails, thumbRequest, delegate;

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
		//[UIView beginAnimations:nil context:NULL];
		//[UIView setAnimationDuration:0.15];
		
		UIView *oldView = [self viewWithTag:selectedThumbIndex];
		UIView *newView = [self viewWithTag:thumbIndex];

		CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1.5, 1.5);
		
		oldView.transform = CGAffineTransformIdentity;
		newView.transform = scaleTransform;
		
		//[UIView commitAnimations];

		[self bringSubviewToFront:newView];
		
		selectedThumbIndex = thumbIndex;
	}
}

- (UIImage *)thumbForIndex:(int)thumbIndex {
	UIImageView *thumbView = (UIImageView *)[self viewWithTag:thumbIndex + 1];
	
	if (thumbView) {
		return thumbView.image;
	} else {
		return nil;
	}
}

- (void)didPanOverThumbnails:(id)sender {
	switch ([(UIPanGestureRecognizer *)sender state]) {
		case UIGestureRecognizerStateEnded: {
			[delegate didFinishPanning];
			
			break;
		}
		default: {
			CGPoint touchPoint = [(UIPanGestureRecognizer *)sender locationInView:self];
			UIView *tappedView = [self hitTest:CGPointMake(touchPoint.x, self.frame.size.height / 2) withEvent:nil];
			
			if (tappedView != nil && tappedView != self) {
				[self selectThumb:tappedView.tag];
				[delegate didPanOverThumbnailWithIndex:tappedView.tag - 1];
			}
			
			break;
		}
	}
}

- (void)didTapOnThumbnail:(id)sender {
	CGPoint touchPoint = [(UITapGestureRecognizer *)sender locationInView:self];
	UIView *tappedView = [self hitTest:CGPointMake(touchPoint.x, self.frame.size.height / 2) withEvent:nil];
	
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
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, PHOTO_WIDTH, PHOTO_HEIGHT)];
		
		[imageView setUserInteractionEnabled:YES];
		[imageView setContentMode:UIViewContentModeCenter];
		[imageView setBackgroundColor:[UIColor blackColor]];
		[imageView setClipsToBounds:YES];
		[imageView setTag:count];
		
		imageView.layer.borderColor = [[UIColor whiteColor] CGColor];
		imageView.layer.borderWidth = 1.0;
		
		[self addSubview:imageView];
		
		[imageView release];
		
		count++;
	}
	
	[self getThumbForIndex:0];
	[self setNeedsLayout];
}

- (void)getThumbForIndex:(int)thumbIndex {
	if (thumbIndex >= [thumbnails count]) {
		return;
	}
	
	[thumbRequest release];
	
	NSString *thumbURL = [thumbnails objectAtIndex:thumbIndex];

	thumbRequest = [[ImageRequest alloc] initWithIdentifier:[thumbURL lastPathComponent] cellIndex:[NSIndexPath indexPathForRow:thumbIndex inSection:0]];
	
	[thumbRequest setDelegate:self];
	[thumbRequest setExactFit:NO];
	[thumbRequest setTargetSize:CGSizeMake(PHOTO_WIDTH * 4, PHOTO_HEIGHT * 4)];
	[thumbRequest sendRequestForURL:[NSURL fileURLWithPath:thumbURL]];
}

- (void)imageRequestDidFail:(ImageRequest *)request forCellIndex:(NSIndexPath *)indexPath {
	NSLog(@"DID FAIL: %d", indexPath.row);
	[self getThumbForIndex:(indexPath.row + 1)];
}

- (void)imageRequestDidSucceed:(ImageRequest *)request withImage:(UIImage *)image cellIndex:(NSIndexPath *)indexPath {
	[(UIImageView *)[self viewWithTag:(indexPath.row + 1)] setImage:image];
	[self getThumbForIndex:(indexPath.row + 1)];
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
	[thumbRequest abortConnection];
	[thumbRequest release];
    [super dealloc];
}

@end
