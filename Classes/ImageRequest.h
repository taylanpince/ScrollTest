//
//  ImageRequest.h
//  WideAngle
//
//  Created by Taylan Pince on 10-04-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import "ImageOperation.h"


@protocol ImageRequestDelegate;

@interface ImageRequest : NSObject <ImageOperationDelegate> {
	NSURLConnection *requestConnection;
	NSOperationQueue *operationQueue;
	NSMutableData *requestData;
	NSInteger statusCode;

	NSString *identifier;
	NSIndexPath *cellIndex;
	CGSize targetSize;
	
	BOOL isCancelled;
	BOOL exactFit;
	
	id <ImageRequestDelegate> delegate;
}

@property (nonatomic, retain) NSURLConnection *requestConnection;
@property (nonatomic, retain) NSOperationQueue *operationQueue;
@property (nonatomic, retain) NSMutableData *requestData;

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSIndexPath *cellIndex;
@property (nonatomic, assign) CGSize targetSize;

@property (nonatomic, assign) BOOL isCancelled;
@property (nonatomic, assign) BOOL exactFit;

@property (nonatomic, assign) id <ImageRequestDelegate> delegate;

- (id)initWithIdentifier:(NSString *)key cellIndex:(NSIndexPath *)indexPath;
- (void)sendRequestForURL:(NSURL *)url;
- (void)abortConnection;
- (void)resetConnection;

@end

@protocol ImageRequestDelegate
- (void)imageRequestDidSucceed:(ImageRequest *)request withImage:(UIImage *)image cellIndex:(NSIndexPath *)indexPath;
- (void)imageRequestDidFail:(ImageRequest *)request forCellIndex:(NSIndexPath *)indexPath;
@end
