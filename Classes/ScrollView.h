//
//  ScrollView.h
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

extern NSUInteger const tagOffset;


@protocol ScrollViewDataSource;

@interface ScrollView : UIScrollView {
	NSMutableSet *reusablePages;
	
	BOOL pagesHidden;
	
	id <ScrollViewDataSource> dataSource;
	int firstVisiblePage, lastVisiblePage;
}

@property (nonatomic, assign) id <ScrollViewDataSource> dataSource;

- (UIView *)dequeueReusablePage;
- (UIView *)viewForPage:(int)page;
- (void)reloadData;
- (void)reloadDataWithNewContentSize:(CGSize)size;
- (void)hideAllPagesExceptPage:(int)page;
- (void)showAllPages;

@end


@protocol ScrollViewDataSource
- (UIView *)scrollView:(ScrollView *)scrollView viewForPage:(int)page;
- (void)scrollView:(ScrollView *)scrollView didAddPage:(int)page;
@end
