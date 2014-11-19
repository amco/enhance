//
//  UIImage+BlurEffects.h
//  Pods
//
//  Created by Adam Yanalunas on 11/18/14.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (BlurEffects)

- (UIImage *)enh_applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;

@end
