//
//  ImageRequest.m
//  WideAngle
//
//  Created by Taylan Pince on 10-04-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import "ImageRequest.h"


@interface ImageRequest (PrivateMethods)
- (void)parseImageFromData:(NSData *)imageData;
- (void)parseCompleteWithImage:(UIImage *)image;
- (void)fetchImageFromFilePath:(NSString *)filePath;
- (void)fetchCompleteWithData:(NSData *)imageData;
@end


@implementation ImageRequest

@synthesize requestConnection, requestData, identifier, cellIndex, targetSize, isCancelled, exactFit, delegate;

- (id)initWithIdentifier:(NSString *)key cellIndex:(NSIndexPath *)indexPath {
	if (self = [super init]) {
		identifier = [key retain];
		cellIndex = [indexPath retain];
		targetSize = CGSizeZero;
		exactFit = NO;
		isCancelled = NO;
	}
	
	return self;
}

- (void)fetchImageFromFilePath:(NSString *)filePath {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSData *fileData = [NSData dataWithContentsOfFile:filePath];
	
	[self performSelectorOnMainThread:@selector(fetchCompleteWithData:) withObject:fileData waitUntilDone:NO];
	
	[pool drain];
}

- (void)parseImageFromData:(NSData *)imageData {
	if (!isCancelled) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (imageData != nil && !isCancelled) {
			NSFileManager *manager = [NSFileManager defaultManager];
			NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
			NSString *cachePath = [savePath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"jpg"]];
			UIImage *sourceImage = [[UIImage alloc] initWithData:imageData];
			UIImage *finalImage;
			
			if (![manager fileExistsAtPath:cachePath]) {
				[manager createFileAtPath:cachePath contents:imageData attributes:nil];
			}
			
			if (sourceImage != nil) {
				CGSize imageSize = sourceImage.size;
				
				if (targetSize.width > 0.0 && targetSize.height > 0.0 && (targetSize.width != imageSize.width || targetSize.height != imageSize.height)) {
					CGImageRef cgImage = NULL;
					
					double scale = MIN(targetSize.width / imageSize.width, targetSize.height / imageSize.height);
					
					imageSize.width = floor(imageSize.width * scale);
					imageSize.height = floor(imageSize.height * scale);
					
					if (exactFit && (targetSize.width != imageSize.width || targetSize.height != imageSize.height)) {
						if (imageSize.width < targetSize.width) {
							double ratio = imageSize.height / imageSize.width;
							
							imageSize.width = targetSize.width;
							imageSize.height = floor(imageSize.width * ratio);
						} else {
							double ratio = imageSize.width / imageSize.height;
							
							imageSize.height = targetSize.height;
							imageSize.width = floor(imageSize.height * ratio);
						}
					}
					
					if (!isCancelled) {
						CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
						CGContextRef context = CGBitmapContextCreate(NULL, targetSize.width, targetSize.height, 8, 0, colorSpace, (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host));
						
						if (context != nil) {
							CGContextSetInterpolationQuality(context, kCGInterpolationLow);
							CGContextSetBlendMode(context, kCGBlendModeCopy);
							
							if (!isCancelled) {
								CGContextDrawImage(context, CGRectMake(floor((targetSize.width - imageSize.width) / 2), floor((targetSize.height - imageSize.height) / 2), imageSize.width, imageSize.height), [sourceImage CGImage]);
							}
							
							if (!isCancelled) {
								cgImage = CGBitmapContextCreateImage(context);
							}
							
							CGContextRelease(context);
						}
						
						CGColorSpaceRelease(colorSpace);
						
						if (cgImage != NULL) {
							finalImage = [[UIImage alloc] initWithCGImage:cgImage];
							
							CGImageRelease(cgImage);
						}
					}
				} else {
					if (!isCancelled) {
						finalImage = [[UIImage alloc] initWithCGImage:[sourceImage CGImage]];
					}
				}
				
				[sourceImage release];
			}
			
			if (finalImage != nil && !isCancelled) {
				[self performSelectorOnMainThread:@selector(parseCompleteWithImage:) withObject:finalImage waitUntilDone:NO];
				[finalImage release];
			}
		}
		
		[pool drain];
	}
}

- (void)fetchCompleteWithData:(NSData *)imageData {
	if (!isCancelled) {
		[self performSelectorInBackground:@selector(parseImageFromData:) withObject:imageData];
	}
}

- (void)parseCompleteWithImage:(UIImage *)image {
	if (!isCancelled) {
		[delegate imageRequestDidSucceed:self withImage:image cellIndex:cellIndex];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[requestData setLength:0];
	
	if ([response respondsToSelector:@selector(statusCode)]) {
		statusCode = [(NSHTTPURLResponse *)response statusCode];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[requestData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[self resetConnection];
	[delegate imageRequestDidFail:self forCellIndex:cellIndex];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (!isCancelled) {
		[self performSelectorInBackground:@selector(parseImageFromData:) withObject:requestData];
	}
}

- (void)sendRequestForURL:(NSURL *)url {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSString *filePath = [savePath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"jpg"]];
	
	if ([manager fileExistsAtPath:filePath]) {
		[self performSelectorInBackground:@selector(fetchImageFromFilePath:) withObject:filePath];
	} else if ([url isFileURL]) {
		[self performSelectorInBackground:@selector(fetchImageFromFilePath:) withObject:[url relativePath]];
	} else {
		[self abortConnection];

		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		
		NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
		
		requestConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		
		if (requestConnection) {
			requestData = [[NSMutableData data] retain];
		} else {
			[self resetConnection];
			[delegate imageRequestDidFail:self forCellIndex:cellIndex];
		}
	}
}

- (void)resetConnection {
	[requestConnection release], requestConnection = nil;
	[requestData release], requestData = nil;
}

- (void)abortConnection {
	isCancelled = YES;
	
	if (requestConnection != nil) {
		[requestConnection cancel];
	}
	
	[self resetConnection];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void)dealloc {
	[self abortConnection];
	[identifier release];
	[cellIndex release];
	[super dealloc];
}

@end
