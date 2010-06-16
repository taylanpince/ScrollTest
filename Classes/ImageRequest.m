//
//  ImageRequest.m
//  WideAngle
//
//  Created by Taylan Pince on 10-04-13.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import "ImageRequest.h"


@implementation ImageRequest

@synthesize requestConnection, operationQueue, requestData, identifier, cellIndex, targetSize, isCancelled, exactFit, delegate;

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

- (NSOperationQueue *)operationQueue {
	if (operationQueue != nil) {
		return operationQueue;
	}
	
	operationQueue = [[NSOperationQueue alloc] init];
	
	[operationQueue setMaxConcurrentOperationCount:1];
	
	return operationQueue;
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
	ImageOperation *operation = [[ImageOperation alloc] initWithImageData:requestData fileIdentifier:identifier targetSize:targetSize exactFit:exactFit];
	
	[operation setDelegate:self];
	[self.operationQueue addOperation:operation];
	[operation release];
}

- (void)didCompleteImageOperationWithImage:(UIImage *)image {
	if (isCancelled) {
		return;
	}
	
	if ([NSThread mainThread]) {
		[delegate imageRequestDidSucceed:self withImage:image cellIndex:cellIndex];
	} else {
		[self performSelectorOnMainThread:@selector(didCompleteImageOperationWithImage:) withObject:image waitUntilDone:NO];
	}
}

- (void)sendRequestForURL:(NSURL *)url {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	NSString *filePath = [savePath stringByAppendingPathComponent:[identifier stringByAppendingPathExtension:@"jpg"]];
	
	if ([manager fileExistsAtPath:filePath]) {
		//NSLog(@"LOAD FROM CACHE: %@", filePath);
		ImageOperation *operation = [[ImageOperation alloc] initWithFilePath:filePath fileIdentifier:identifier targetSize:targetSize exactFit:exactFit];
		
		[operation setDelegate:self];
		[self.operationQueue addOperation:operation];
		[operation release];
	} else if ([url isFileURL]) {
		//NSLog(@"LOAD FROM LOCAL: %@", [url relativePath]);
		ImageOperation *operation = [[ImageOperation alloc] initWithFilePath:[url relativePath] fileIdentifier:identifier targetSize:targetSize exactFit:exactFit];
		
		[operation setDelegate:self];
		[self.operationQueue addOperation:operation];
		[operation release];
	} else {
		[self abortConnection];
		//NSLog(@"LOAD FROM WEB: %@", [url absoluteString]);
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
	[operationQueue release], operationQueue = nil;
}

- (void)abortConnection {
	isCancelled = YES;
	
	[operationQueue cancelAllOperations];
	
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
