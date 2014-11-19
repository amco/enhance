//
//  UIImage+ENHAnimatedGif.h
//  Pods
//
//  Created by Adam Yanalunas on 11/18/14.
//
//


#import <UIKit/UIKit.h>


/**
 *  Animated GIF category and utility methods from https://github.com/mayoff/uiimage-from-animated-gif
 */
@interface UIImage (ENHAnimatedGif)

+ (UIImage *)enh_animatedImageWithAnimatedGIFData:(NSData *)data;
+ (UIImage *)enh_animatedImageWithAnimatedGIFURL:(NSURL *)url;

@end
