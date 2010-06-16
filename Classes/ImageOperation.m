//
//  ImageOperation.m
//  ScrollTest
//
//  Created by Taylan Pince on 10-06-15.
//  Copyright 2010 Hippo Foundry. All rights reserved.
//

#import "ImageOperation.h"


@implementation ImageOperation

@synthesize imageData, filePath, fileIdentifier, targetSize, exactFit, delegate;

- (id)initWithImageData:(NSData *)data fileIdentifier:(NSString *)identifier targetSize:(CGSize)size exactFit:(BOOL)fit {
	if (self = [super init]) {
		imageData = [data retain];
		fileIdentifier = [identifier retain];
		targetSize = size;
		exactFit = fit;
	}
	
	return self;
}

- (id)initWithFilePath:(NSString *)path fileIdentifier:(NSString *)identifier targetSize:(CGSize)size exactFit:(BOOL)fit {
	if (self = [super init]) {
		filePath = [path retain];
		fileIdentifier = [identifier retain];
		targetSize = size;
		exactFit = fit;
	}
	
	return self;
}

- (void)main {
	if (![self isCancelled]) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		if (filePath) {
			imageData = [[NSData dataWithContentsOfFile:filePath] retain];
		}
		
		if (imageData != nil && ![self isCancelled]) {
			NSFileManager *manager = [NSFileManager defaultManager];
			NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
			NSString *cachePath = [savePath stringByAppendingPathComponent:[fileIdentifier stringByAppendingPathExtension:@"jpg"]];
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
					
					if (![self isCancelled]) {
						CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
						CGContextRef context = CGBitmapContextCreate(NULL, targetSize.width, targetSize.height, 8, 0, colorSpace, (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host));
						
						if (context != nil) {
							CGContextSetInterpolationQuality(context, kCGInterpolationLow);
							CGContextSetBlendMode(context, kCGBlendModeCopy);
							
							if (![self isCancelled]) {
								CGContextDrawImage(context, CGRectMake(floor((targetSize.width - imageSize.width) / 2), floor((targetSize.height - imageSize.height) / 2), imageSize.width, imageSize.height), [sourceImage CGImage]);
							}
							
							if (![self isCancelled]) {
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
					if (![self isCancelled]) {
						finalImage = [[UIImage alloc] initWithCGImage:[sourceImage CGImage]];
					}
				}
				
				[sourceImage release];
			}
			
			if (finalImage != nil && ![self isCancelled] && delegate) {
				[delegate didCompleteImageOperationWithImage:finalImage];
				[finalImage release];
			}
		}
		
		[pool drain];
	}
}

- (void)dealloc {
	[imageData release], imageData = nil;
	[filePath release], filePath = nil;
	[fileIdentifier release], fileIdentifier = nil;
	[super dealloc];
}

@end
