//
//  ImageRequest.h
//  WideAngle
//
//  Created by Taylan Pince on 10-04-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//


@protocol ImageRequestDelegate;

@interface ImageRequest : NSObject {
	NSURLConnection *requestConnection;
	NSMutableData *requestData;
	NSInteger statusCode;

	NSString *identifier;
	NSIndexPath *cellIndex;
	CGSize targetSize;
	
	BOOL isActive;
	BOOL exactFit;
	
	id <ImageRequestDelegate> delegate;
}

@property (nonatomic, retain) NSURLConnection *requestConnection;
@property (nonatomic, retain) NSMutableData *requestData;

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSIndexPath *cellIndex;
@property (nonatomic, assign) CGSize targetSize;

@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) BOOL exactFit;

@property (nonatomic, assign) id <ImageRequestDelegate> delegate;

- (id)initWithIdentifier:(NSString *)key cellIndex:(NSIndexPath *)indexPath;
- (void)sendRequestForURL:(NSURL *)url;
- (void)abortConnection;
- (void)resetConnection;

@end

@protocol ImageRequestDelegate
- (void)imageRequestDidSucceedWithImage:(UIImage *)image cellIndex:(NSIndexPath *)indexPath;
- (void)imageRequestDidFailForCellIndex:(NSIndexPath *)indexPath;
@end
