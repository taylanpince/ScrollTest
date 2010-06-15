//
//  ImageRequest.m
//  WideAngle
//
//  Created by Taylan Pince on 10-04-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import "ImageRequest.h"


@interface ImageRequest (PrivateMethods)
- (void)parseImageFromData:(NSData *)data;
- (void)parseCompleteWithImage:(UIImage *)image;
- (void)fetchImageFromFilePath:(NSString *)filePath;
- (void)fetchCompleteWithData:(NSData *)data;
@end


@implementation ImageRequest

@synthesize requestConnection, requestData, identifier, cellIndex, targetSize, isActive, exactFit, delegate;

- (id)initWithIdentifier:(NSString *)key cellIndex:(NSIndexPath *)indexPath {
	if (self = [super init]) {
		identifier = [key retain];
		cellIndex = [indexPath retain];
		targetSize = CGSizeZero;
		exactFit = NO;
		isActive = NO;
	}
	
	return self;
}

- (void)fetchImageFromFilePath:(NSString *)filePath {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSData *fileData = [NSData dataWithContentsOfFile:filePath];

	[self performSelectorOnMainThread:@selector(fetchCompleteWithData:) withObject:fileData waitUntilDone:NO];
	
	[pool drain];
}

- (void)parseImageFromData:(NSData *)data {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSString *filePath = [savePath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"jpg"]];
	UIImage *sourceImage = [[UIImage alloc] initWithData:data];
	UIImage *finalImage = nil;

	if (![manager fileExistsAtPath:filePath]) {
		[manager createFileAtPath:filePath contents:data attributes:nil];
	}

	if (sourceImage != nil) {
		CGSize imageSize = sourceImage.size;
		
		if (targetSize.width != imageSize.width || targetSize.height != imageSize.height) {
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
			
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGContextRef context = CGBitmapContextCreate(NULL, targetSize.width, targetSize.height, 8, 0, colorSpace, (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host));
			
			if (context != nil) {
				CGContextSetInterpolationQuality(context, kCGInterpolationLow);
				CGContextSetBlendMode(context, kCGBlendModeCopy);
				
				CGContextDrawImage(context, CGRectMake(floor((targetSize.width - imageSize.width) / 2), floor((targetSize.height - imageSize.height) / 2), imageSize.width, imageSize.height), [sourceImage CGImage]);
				
				cgImage = CGBitmapContextCreateImage(context);
				
				CGContextRelease(context);
			}
			
			CGColorSpaceRelease(colorSpace);
			
			if (cgImage != NULL) {
				finalImage = [[UIImage alloc] initWithCGImage:cgImage];
				
				CGImageRelease(cgImage);
			}
		} else {
			finalImage = [[UIImage alloc] initWithCGImage:[sourceImage CGImage]];
		}
		
		[sourceImage release];
	}

	if (finalImage != nil) {
		[self performSelectorOnMainThread:@selector(parseCompleteWithImage:) withObject:finalImage waitUntilDone:NO];
		[finalImage release];
	}
	
	[pool drain];
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
	[delegate imageRequestDidFailForCellIndex:cellIndex];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[self performSelectorInBackground:@selector(parseImageFromData:) withObject:requestData];
}

- (void)fetchCompleteWithData:(NSData *)data {
	[self performSelectorInBackground:@selector(parseImageFromData:) withObject:data];
}

- (void)parseCompleteWithImage:(UIImage *)image {
	[delegate imageRequestDidSucceedWithImage:image cellIndex:cellIndex];
}

- (void)sendRequestForURL:(NSURL *)url {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSString *filePath = [savePath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"jpg"]];
	
	if ([manager fileExistsAtPath:filePath]) {
		NSLog(@"LOAD FROM CACHE: %@", filePath);
		[self performSelectorInBackground:@selector(fetchImageFromFilePath:) withObject:filePath];
	} else if ([url isFileURL]) {
		NSLog(@"LOAD FROM LOCAL: %@", [url relativePath]);
		[self performSelectorInBackground:@selector(fetchImageFromFilePath:) withObject:[url relativePath]];
	} else {
		isActive = YES;

		[self abortConnection];
		NSLog(@"LOAD FROM WEB: %@", [url absoluteString]);
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		
		NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
		
		requestConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
		
		if (requestConnection) {
			requestData = [[NSMutableData data] retain];
		} else {
			[self resetConnection];
			[delegate imageRequestDidFailForCellIndex:cellIndex];
		}
	}
}

- (void)resetConnection {
	[requestConnection release];
	[requestData release];
	
	requestConnection = nil;
	requestData = nil;
	
	isActive = NO;
}

- (void)abortConnection {
	if (requestConnection != nil) {
		[requestConnection cancel];
		
		[requestConnection release];
		
		requestConnection = nil;
		
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
	
	[requestData release];
	
	requestData = nil;
}

- (void)dealloc {
	[self abortConnection];
	[identifier release];
	[cellIndex release];
	[super dealloc];
}

@end
