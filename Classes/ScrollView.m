//
//  ScrollView.m
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import "ScrollView.h"


@interface ScrollView (PrivateMethods)
- (void)didPinch:(id)sender;
@end


NSUInteger const tagOffset = 999;


@implementation ScrollView

@synthesize dataSource;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
		reusablePages = [[NSMutableSet alloc] init];
		
		[self setBackgroundColor:[UIColor blackColor]];
		[self setDirectionalLockEnabled:YES];
		[self setShowsVerticalScrollIndicator:NO];
		[self setShowsHorizontalScrollIndicator:NO];
		[self setScrollsToTop:NO];
		[self setPagingEnabled:YES];
		
		UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(didPinch:)];
		
		[self addGestureRecognizer:pinchGesture];
		
		[pinchGesture release];
		
		firstVisiblePage = NSIntegerMax;
		lastVisiblePage = NSIntegerMin;
		pagesHidden = NO;
    }
	
    return self;
}

- (void)didPinch:(id)sender {
	switch ([(UIPinchGestureRecognizer *)sender state]) {
		case UIGestureRecognizerStateBegan:
			[dataSource scrollView:self willBeingPinching:[(UIPinchGestureRecognizer *)sender scale]];
			break;
		case UIGestureRecognizerStateEnded:
			[dataSource scrollView:self didEndPinching:[(UIPinchGestureRecognizer *)sender scale]];
			break;
		default:
			[dataSource scrollView:self didPinch:[(UIPinchGestureRecognizer *)sender scale]];
			break;
	}
}

- (UIView *)dequeueReusablePage {
    UIView *page = [reusablePages anyObject];
	
    if (page) {
        [[page retain] autorelease];
        [reusablePages removeObject:page];
    }
    
	return page;
}

- (UIView *)viewForPage:(int)page {
	return [self viewWithTag:(page + tagOffset)];
}

- (void)reloadData {
    for (UIView *pageView in [self subviews]) {
        [reusablePages addObject:pageView];
        [pageView removeFromSuperview];
    }
    
	firstVisiblePage = NSIntegerMax;
	lastVisiblePage = NSIntegerMin;
	
    [self setNeedsLayout];
}

- (void)reloadDataWithNewContentSize:(CGSize)size {
	if (self.contentSize.width != size.width || self.contentSize.height != size.height) {
		[self setContentSize:size];
		[self reloadData];
	}
}

- (void)hideAllPagesExceptPage:(int)page {
	pagesHidden = YES;
	
	for (UIView *pageView in [self subviews]) {
		if ((pageView.tag - tagOffset) != page) {
			[pageView setHidden:YES];
		}
	}
}

- (void)showAllPages {
	pagesHidden = NO;
	
	for (UIView *pageView in [self subviews]) {
		[pageView setHidden:NO];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];

	if (self.contentSize.width == 0.0) {
		return;
	}
	
	for (UIView *pageView in [self subviews]) {
		if ((pageView.tag - tagOffset) < firstVisiblePage || (pageView.tag - tagOffset) > lastVisiblePage) {
			[reusablePages addObject:pageView];
			[pageView removeFromSuperview];
		}
	}
	
	int firstPage = MAX(0, floorf(self.contentOffset.x / self.frame.size.width));
	int lastPage = MIN(floorf(self.contentSize.width / self.frame.size.width), floorf((self.contentOffset.x + self.frame.size.width) / self.frame.size.width));
	
	for (int pageIndex = firstPage; pageIndex <= lastPage; pageIndex++) {
		if (firstVisiblePage > pageIndex || lastVisiblePage < pageIndex) {
			UIView *page = [dataSource scrollView:self viewForPage:pageIndex];

			if (page != nil) {
				[page setFrame:CGRectMake(pageIndex * self.frame.size.width, 0.0, self.frame.size.width - 20.0, self.frame.size.height)];
				[page setTag:(pageIndex + tagOffset)];
				[page setHidden:pagesHidden];

				[self addSubview:page];
				
				[dataSource scrollView:self didAddPage:pageIndex];
			}
		}
	}
	
	firstVisiblePage = firstPage;
	lastVisiblePage = lastPage;
}

- (void)dealloc {
	[reusablePages release];
    [super dealloc];
}

@end
