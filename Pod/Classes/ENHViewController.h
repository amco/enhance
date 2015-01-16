//
//  ENHViewController.h
//  Pods
//
//  Created by Adam Yanalunas on 11/12/14.
//
//


#import <UIKit/UIKit.h>


NS_OPTIONS(NSInteger, ENHErrorCode) {
    ENHImageLoadFailed
};


@class ENHViewController;


@protocol ENHViewControllerDelegate <NSObject>
@optional

/**
 *  Tells the delegate that the controller's view is visisble. This is called after all presentation animations have completed.
 *
 *  @param enhanceViewController The instance that triggered the event.
 */
- (void)enhanceViewControllerDidAppear:(ENHViewController *)enhanceViewController;

/**
 *  Tells the delegate that the controller's view has been removed and is no longer visible. This is called after all dismissal animations have completed.
 *
 *  @param enhanceViewController The instance the triggered the event.
 */
- (void)enhanceViewControllerDidDisappear:(ENHViewController *)enhanceViewController;


/**
 *  Tells the delegate that the controller registered a tap gesture on the image ivew. This is called when a valid tap gesture starts
 *
 *  @param enhanceViewController The instance of the controller recognizing the event
 *  @param gestureRecognizer     The instance of the tap gesture
 */
- (void)enhanceViewController:(ENHViewController *)enhanceViewController didRegisterTap:(UITapGestureRecognizer *)gestureRecognizer;

/**
 *  Tells the delegate that the controller registered a long press on the image view. This is called for every state of the tap gesture so filter by state accordingly.
 *
 *  @param enhanceViewController The instance of the controller recognizing the event
 *  @param gestureRecognizer     The instance of the long press
 */
- (void)enhanceViewController:(ENHViewController *)enhanceViewController didRegisterLongPress:(UILongPressGestureRecognizer *)gestureRecognizer;

/**
 *  Tells the delegate that the remote image needed for presentation has successfully loaded.
 *
 *  @param enhanceViewController The instance that triggered the event.
 *  @param image                 The image that was successfully loaded and used for the focus view.
 */
- (void)enhanceViewController:(ENHViewController *)enhanceViewController didFinishLoadingImage:(UIImage *)image;

/**
 *  Tells the delegate that there was an error when requesting the remote image needed for presentation.
 *
 *  @param enhanceViewController The instance that triggered the event.
 *  @param error                 The error returned by the internal request.
 */
- (void)enhanceViewController:(ENHViewController *)enhanceViewController didFailLoadingImageWithError:(NSError *)error;

@end


@interface ENHViewController : UIViewController <UIDynamicAnimatorDelegate, UIGestureRecognizerDelegate, NSURLConnectionDataDelegate>


@property (nonatomic, assign) BOOL shouldBlurBackground;
@property (nonatomic, assign) BOOL parallaxEnabled;

// determines whether or not to hide the status bar
@property (nonatomic, assign) BOOL shouldHideStatusBar;

// determines whether or not view should be dismissed when the container view is tapped anywhere outside image bounds
@property (nonatomic, assign) BOOL shouldDismissOnTap;

// determines whether or not view should be dismissed when the container view is tapped within bounds of image view
@property (nonatomic, assign) BOOL shouldDismissOnImageTap;

// determines if photo action sheet should appear with a long press on the photo (default NO)
@property (nonatomic, assign) BOOL shouldShowPhotoActions;

//determines if view should rotate when the device orientation changes (default YES)
@property (nonatomic, assign) BOOL shouldRotateToDeviceOrientation;

@property (nonatomic, weak) id<ENHViewControllerDelegate> delegate;

// HTTP header values included in URL requests
@property (nonatomic, strong) NSDictionary *requestHTTPHeaders;

// Visibility to the state of the user interaction lock
@property (nonatomic, assign, readonly, getter=isRespondingToTaps) BOOL respondsToTap;


/**
 * Designated initializer to capture the parent view controller
 *
 * @param viewController The parent view controller to which enhance views are added
 */
+ (instancetype)enhanceUsingViewController:(UIViewController *)viewController;


/**
 *  Convenience method for not using a parentViewController.
 *  @see showImage:fromView:inViewController
 */
- (void)showImage:(UIImage *)image fromView:(UIView *)fromView;

/**
 *  Presents focus view from a specific CGRect, useful for using with images located within UIWebViews.
 *
 *  @param image    The full size image to show, which should be an image already cached on the device or within the app's bundle.
 *  @param fromRect The CGRect from which the image should be presented from.
 */
- (void)showImage:(UIImage *)image fromRect:(CGRect)fromRect;

/**
 *  Convenience method for not using a parentViewController.
 *  @see showImageFromURL:fromView:inViewController
 */
- (void)showImageFromURL:(NSURL *)url fromView:(UIView *)fromView;

/**
 *  Presents media from a specific CGRect after being requested from the specified URL. The `URBMediaFocusViewController` will
 *	only present its view once the image has been successfully loaded.
 *
 *  @param url      The remote url of the full size image that will be requested and displayed.
 *  @param fromRect The CGRect from which the image should be presented from.
 */
- (void)showImageFromURL:(NSURL *)url fromRect:(CGRect)fromRect;

/**
 *  Dismiss view
 *  @param animated Dismiss animated or not
 */
- (void)dismiss:(BOOL)animated;

/**
 *  Stop downloading the image (useful when closing a window while the image is downloading)
 */
- (void)cancelURLConnectionIfAny;


/**
 *  Bundle for enhance resources
 */
+ (NSBundle *)enhanceBundle;


/**
 *  Prevents image views from recognizing tap gestures
 */
- (void)preventTaps;


/**
 *  Allows image views to recognize tap gestures
 */
- (void)allowTaps;


@end
