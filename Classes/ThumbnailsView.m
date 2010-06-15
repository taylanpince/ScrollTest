//
//  ThumbnailsView.m
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import "ThumbnailsView.h"


@interface ThumbnailsView (PrivateMethods)
- (void)didTapOnThumbnail:(id)sender;
- (void)didPanOverThumbnails:(id)sender;
@end


@implementation ThumbnailsView

@synthesize delegate;

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
		[UIView setAnimationDuration:0.25];
		
		UIView *oldView = [self viewWithTag:selectedThumbIndex];
		UIView *newView = [self viewWithTag:thumbIndex];
		
		CGAffineTransform scaleTransform = CGAffineTransformMakeScale(3.0, 3.0);
		
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
		[delegate didTapOnThumbnailWithIndex:tappedView.tag];
	}
}

- (void)didTapOnThumbnail:(id)sender {
	CGPoint touchPoint = [(UITapGestureRecognizer *)sender locationInView:self];
	UIView *tappedView = [self hitTest:touchPoint withEvent:nil];
	
	if (tappedView != nil && tappedView != self) {
		[self selectThumb:tappedView.tag];
		[delegate didTapOnThumbnailWithIndex:tappedView.tag];
	}
}

- (void)loadThumbnails:(NSArray *)thumbnails {
	int count = 0;
	NSLog(@"THUMBS: %d", [thumbnails count]);
	for (NSString *thumb in thumbnails) {
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[thumb lastPathComponent]]];
		
		[imageView setUserInteractionEnabled:YES];
		[imageView setContentMode:UIViewContentModeScaleAspectFit];
		[imageView setClipsToBounds:YES];
		[imageView setTag:count];
		
		[self addSubview:imageView];
		
		[imageView release];
		
		count++;
	}
	
	[self setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat photoWidth = floorf(self.frame.size.width / [[self subviews] count]);
	CGFloat leftOffset = (photoWidth * [[self subviews] count] < self.frame.size.width) ? floorf((self.frame.size.width - (photoWidth * [[self subviews] count])) / 2) : 0.0;
	NSUInteger photoCount = 0;
	NSLog(@"PHOTO WIDTH: %f", photoWidth);
	NSLog(@"LEFT OFFSET: %f", leftOffset);
	NSLog(@"FRAME WIDTH: %f", self.frame.size.width);
	NSLog(@"PHOTOS: %d", [[self subviews] count]);
	for (UIView *subView in [self subviews]) {
		if (selectedThumbIndex == photoCount) {
			[subView setFrame:CGRectMake(leftOffset + (photoCount * photoWidth), 10.0, photoWidth, self.frame.size.height * 0.75)];
		} else {
			[subView setFrame:CGRectMake(leftOffset + (photoCount * photoWidth), 10.0, photoWidth, self.frame.size.height * 0.75)];
		}

		photoCount++;
	}
}

- (void)dealloc {
    [super dealloc];
}


@end
