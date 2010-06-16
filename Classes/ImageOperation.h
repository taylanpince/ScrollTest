//
//  ImageOperation.h
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-15.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//


@protocol ImageOperationDelegate;

@interface ImageOperation : NSOperation {
	NSData *imageData;
	NSString *filePath;
	NSString *fileIdentifier;

	CGSize targetSize;
	
	BOOL exactFit;
	
	id <ImageOperationDelegate> delegate;
}

@property (nonatomic, retain) NSData *imageData;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSString *fileIdentifier;
@property (nonatomic, assign) CGSize targetSize;
@property (nonatomic, assign) BOOL exactFit;

@property (nonatomic, assign) id <ImageOperationDelegate> delegate;

- (id)initWithImageData:(NSData *)data fileIdentifier:(NSString *)identifier targetSize:(CGSize)size exactFit:(BOOL)fit;
- (id)initWithFilePath:(NSString *)path fileIdentifier:(NSString *)identifier targetSize:(CGSize)size exactFit:(BOOL)fit;

@end


@protocol ImageOperationDelegate
- (void)didCompleteImageOperationWithImage:(UIImage *)image;
@end