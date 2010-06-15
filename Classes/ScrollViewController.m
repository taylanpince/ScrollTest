//
//  ScrollViewController.m
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import "ScrollViewController.h"


@interface ScrollViewController (PrivateMethods)
- (void)goToPage:(int)page;
@end


@implementation ScrollViewController

@synthesize scrollView, thumbsView, photos, imageRequests;

- (void)loadView {
	UIView *mainView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	[mainView setBackgroundColor:[UIColor blackColor]];
	
	self.view = mainView;
	
	[mainView release];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setTitle:@"Scroll Test"];
	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
	[self setWantsFullScreenLayout:YES];
	
	CGSize dimensions = (UIDeviceOrientationIsPortrait(self.interfaceOrientation)) ? CGSizeMake(self.view.frame.size.width, self.view.frame.size.height) : CGSizeMake(self.view.frame.size.height, self.view.frame.size.width);

	scrollView = [[ScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, dimensions.width + 20.0, dimensions.height)];
	
	[scrollView setDelegate:self];
	[scrollView setDataSource:self];
	[scrollView setBackgroundColor:[UIColor blackColor]];
	
	[self.view addSubview:scrollView];
	
	[scrollView reloadDataWithNewContentSize:CGSizeMake(dimensions.width * [self.photos count], dimensions.height)];
	
	thumbsView = [[ThumbnailsView alloc] initWithFrame:CGRectMake(0.0, 0.0, dimensions.width - 20.0, 52.0)];
	
	[thumbsView setDelegate:self];
	[thumbsView setThumbnails:self.photos];
	
	UIBarButtonItem *thumbsButtonItem = [[UIBarButtonItem alloc] initWithCustomView:thumbsView];
	
	[self setToolbarItems:[NSArray arrayWithObject:thumbsButtonItem]];
	
	[thumbsButtonItem release];
	
	[self.navigationController.toolbar setBarStyle:UIBarStyleBlackTranslucent];
	[self.navigationController setToolbarHidden:NO animated:NO];
	
	imageRequests = [[NSMutableArray alloc] init];
	activePhotoIndex = 0;
	
	for (int photoIndex = 0; photoIndex < [self.photos count]; photoIndex++) {
		[imageRequests addObject:[NSNull null]];
	}
}

- (void)goToPage:(int)page {
	if (page < [self.photos count]) {
		[scrollView setContentOffset:CGPointMake(page * scrollView.frame.size.width, 0.0)];
		
		activePhotoIndex = page;
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[scrollView setScrollEnabled:NO];
	[scrollView hideAllPagesExceptPage:activePhotoIndex];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
	[scrollView setFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width + 20.0, self.view.frame.size.height)];
	[thumbsView setFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width - 20.0, 52.0)];
	[[scrollView viewForPage:activePhotoIndex] setFrame:CGRectMake(scrollView.contentOffset.x, 0.0, scrollView.frame.size.width - 20.0, scrollView.frame.size.height)];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[scrollView reloadDataWithNewContentSize:CGSizeMake([self.photos count] * scrollView.frame.size.width, scrollView.frame.size.height)];
	[scrollView setContentOffset:CGPointMake(activePhotoIndex * scrollView.frame.size.width, 0.0)];
	[scrollView showAllPages];
	[scrollView setScrollEnabled:YES];
}

- (NSArray *)photos {
	if (photos != nil) {
		return photos;
	}
	
	NSMutableArray *pathsList = [[NSMutableArray alloc] init];
	
	[pathsList addObjectsFromArray:[[[NSBundle mainBundle] pathsForResourcesOfType:@"PNG" inDirectory:nil] retain]];
	[pathsList addObjectsFromArray:[[[NSBundle mainBundle] pathsForResourcesOfType:@"png" inDirectory:nil] retain]];
	[pathsList addObjectsFromArray:[[[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:nil] retain]];

	photos = [[NSArray alloc] initWithArray:pathsList];
	
	[pathsList release];

	return photos;
}

- (UIView *)scrollView:(ScrollView *)aScrollView viewForPage:(int)page {
	UIImageView *photoView = (UIImageView *)[scrollView dequeueReusablePage];
	
	if (photoView == nil) {
		photoView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
		
		[photoView setContentMode:UIViewContentModeCenter];
	}
	
	if (page >= [self.photos count]) {
		return nil;
	}
	
	NSString *photoPath = [self.photos objectAtIndex:page];
	ImageRequest *fetchRequest = [[ImageRequest alloc] initWithIdentifier:[photoPath lastPathComponent] cellIndex:[NSIndexPath indexPathForRow:page inSection:0]];
	
	[fetchRequest setDelegate:self];
	[fetchRequest setTargetSize:CGSizeMake(scrollView.frame.size.width - 20.0, scrollView.frame.size.height)];
	[fetchRequest sendRequestForURL:[NSURL fileURLWithPath:photoPath]];
	[imageRequests replaceObjectAtIndex:page withObject:fetchRequest];
	[fetchRequest release];
	
	return photoView;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
	activePhotoIndex = floorf(scrollView.contentOffset.x / scrollView.frame.size.width);
	
	[thumbsView selectThumb:activePhotoIndex + 1];
}

- (void)abortAllRequests {
	for (int index = 0; index < [imageRequests count]; index++) {
		if ((NSNull *)[imageRequests objectAtIndex:index] != [NSNull null]) {
			[(ImageRequest *)[imageRequests objectAtIndex:index] abortConnection];
			[imageRequests replaceObjectAtIndex:index withObject:[NSNull null]];
		}
	}
}

- (void)imageRequestDidSucceedWithImage:(UIImage *)image cellIndex:(NSIndexPath *)indexPath {
	UIImageView *imageView = (UIImageView *)[scrollView viewForPage:indexPath.row];
	
	if (imageView != nil) {
		[imageView setImage:image];
	}
	
	if ((NSNull *)[imageRequests objectAtIndex:indexPath.row] != [NSNull null]) {
		[imageRequests replaceObjectAtIndex:indexPath.row withObject:[NSNull null]];
	}
}

- (void)imageRequestDidFailForCellIndex:(NSIndexPath *)indexPath {
	UIImageView *imageView = (UIImageView *)[scrollView viewForPage:indexPath.row];
	
	if (imageView != nil) {
		// TODO: Update loader with fail icon
	}
	
	if ((NSNull *)[imageRequests objectAtIndex:indexPath.row] != [NSNull null]) {
		[imageRequests replaceObjectAtIndex:indexPath.row withObject:[NSNull null]];
	}
}

- (void)didTapOnThumbnailWithIndex:(int)thumbIndex {
	[self goToPage:thumbIndex];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	[photos release];
	
	photos = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
	[scrollView release];
	[thumbsView release];
	
	scrollView = nil;
	thumbsView = nil;
}

- (void)dealloc {
	[photos release];
	[scrollView release];
	[thumbsView release];
	[imageRequests release];
    [super dealloc];
}

@end
