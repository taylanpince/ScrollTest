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
- (void)didTapOnPhoto:(id)sender;
- (void)hideInterface;
- (void)showInterface;
- (void)transitionDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
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
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnPhoto:)];
	
	[scrollView addGestureRecognizer:tapGesture];
	
	[tapGesture release];
	
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

- (void)didTapOnPhoto:(id)sender {
	if (self.navigationController.navigationBarHidden) {
		[self showInterface];
	} else {
		[self hideInterface];
	}
}

- (void)goToPage:(int)page {
	if (page < [self.photos count]) {
		[scrollView setContentOffset:CGPointMake(page * scrollView.frame.size.width, 0.0)];
		
		activePhotoIndex = page;
	}
}

- (void)hideInterface {
	if (!self.navigationController.navigationBarHidden) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(transitionDidStop:finished:context:)];
		[self.navigationController.navigationBar setAlpha:0.0];
		[self.navigationController.toolbar setAlpha:0.0];
		[UIView commitAnimations];
		
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
	}
}

- (void)showInterface {
	if (self.navigationController.navigationBarHidden) {
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

		[self.navigationController setNavigationBarHidden:NO animated:NO];
		[self.navigationController setToolbarHidden:NO animated:NO];
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.5];
		[self.navigationController.navigationBar setAlpha:1.0];
		[self.navigationController.toolbar setAlpha:1.0];
		[UIView commitAnimations];
	}
}

- (void)transitionDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	[self.navigationController setToolbarHidden:YES animated:NO];
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
	
	[pathsList addObjectsFromArray:[[NSBundle mainBundle] pathsForResourcesOfType:@"PNG" inDirectory:nil]];
	[pathsList addObjectsFromArray:[[NSBundle mainBundle] pathsForResourcesOfType:@"png" inDirectory:nil]];
	[pathsList addObjectsFromArray:[[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:nil]];

	photos = [[NSArray alloc] initWithArray:pathsList];
	
	[pathsList release];

	return photos;
}

- (UIView *)scrollView:(ScrollView *)aScrollView viewForPage:(int)page {
	UIImageView *photoView = (UIImageView *)[scrollView dequeueReusablePage];
	
	if (photoView == nil) {
		photoView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
		
		[photoView setContentMode:UIViewContentModeScaleAspectFit];
	}
	
	if (page >= [self.photos count]) {
		return nil;
	}
	
	[photoView setImage:[thumbsView thumbForIndex:page]];
	
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
	NSUInteger newPhotoIndex = floorf(scrollView.contentOffset.x / scrollView.frame.size.width);
	
	if (activePhotoIndex != newPhotoIndex) {
		activePhotoIndex = newPhotoIndex;
		
		[thumbsView selectThumb:activePhotoIndex + 1];
		
		[self hideInterface];
	}
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
