//
//  UIView+SnapshotImage.m
//  Pods
//
//  Created by Adam Yanalunas on 11/18/14.
//
//


#import "UIView+SnapshotImage.h"


@implementation UIView (SnapshotImage)


- (UIImage *)enh_snapshotImageWithScale:(CGFloat)scale {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, scale);
    if ([self respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    }
    else {
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end
