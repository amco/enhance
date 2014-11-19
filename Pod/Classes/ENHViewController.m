//
//  ENHViewController.m
//  Pods
//
//  Created by Adam Yanalunas on 11/12/14.
//
//


#import <AssetsLibrary/AssetsLibrary.h>
#import "ENHViewController.h"
#import "UIImage+ENHAnimatedGif.h"
#import "UIImage+BlurEffects.h"
#import "UIView+SnapshotImage.h"


static const CGFloat __overlayAlpha = 0.6f;						// opacity of the black overlay displayed below the focused image
static const CGFloat __animationDuration = 0.18f;				// the base duration for present/dismiss animations (except physics-related ones)
static const CGFloat __maximumDismissDelay = 0.5f;				// maximum time of delay (in seconds) between when image view is push out and dismissal animations begin
static const CGFloat __resistance = 0.0f;						// linear resistance applied to the image’s dynamic item behavior
static const CGFloat __density = 1.0f;							// relative mass density applied to the image's dynamic item behavior
static const CGFloat __velocityFactor = 1.0f;					// affects how quickly the view is pushed out of the view
static const CGFloat __angularVelocityFactor = 1.0f;			// adjusts the amount of spin applied to the view during a push force, increases towards the view bounds
static const CGFloat __minimumVelocityRequiredForPush = 50.0f;	// defines how much velocity is required for the push behavior to be applied

/* parallax options */
static const CGFloat __backgroundScale = 0.9f;					// defines how much the background view should be scaled
static const CGFloat __blurRadius = 2.0f;						// defines how much the background view is blurred
static const CGFloat __blurSaturationDeltaMask = 0.8f;
static const CGFloat __blurTintColorAlpha = 0.2f;				// defines how much to tint the background view


@interface ENHViewController () <UIScrollViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIView *fromView;
@property (nonatomic, assign) CGRect fromRect;
@property (nonatomic, weak) UIViewController *targetViewController;

@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UIScrollView *scrollView;
@property (retain, nonatomic) IBOutlet UIView *backgroundView;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UISnapBehavior *snapBehavior;
@property (nonatomic, strong) UIPushBehavior *pushBehavior;
@property (nonatomic, strong) UIAttachmentBehavior *panAttachmentBehavior;
@property (nonatomic, strong) UIDynamicItemBehavior *itemBehavior;

@property (nonatomic, readonly) UIWindow *keyWindow;

@property (retain, nonatomic) IBOutlet UITapGestureRecognizer *doubleTapRecognizer;
@property (retain, nonatomic) IBOutlet UITapGestureRecognizer *tapRecognizer;
@property (retain, nonatomic) IBOutlet UILongPressGestureRecognizer *photoLongPressRecognizer;
@property (retain, nonatomic) IBOutlet UIPanGestureRecognizer *panRecognizer;


@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, strong) NSMutableData *urlData;

@property (nonatomic, strong) UIView *blurredSnapshotView;
@property (nonatomic, strong) UIView *snapshotView;

@property (nonatomic, assign, getter=isRespondingToTaps) BOOL respondsToTap;
@property (nonatomic, strong) UIMenuController *actionMenuController;


- (IBAction)handleDismissFromTap:(UITapGestureRecognizer *)gestureRecognizer;
- (IBAction)handleDoubleTapGesture:(UITapGestureRecognizer *)gestureRecognizer;
- (IBAction)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer;
- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer;

- (void)handleMenuSaveImage;
- (void)handleMenuCopyImage;

@end


@implementation ENHViewController {
    CGRect _originalFrame;
    CGFloat _minScale;
    CGFloat _maxScale;
    CGFloat _lastPinchScale;
    CGFloat _lastZoomScale;
    BOOL _hasLaidOut;
    BOOL _unhideStatusBarOnDismiss;
}


+ (instancetype)enhanceUsingViewController:(UIViewController *)viewController
{
    NSBundle *bundle = [self.class enhanceBundle];
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"enhance" bundle:bundle];
    ENHViewController *vc = [sb instantiateInitialViewController];
    if (!vc) return nil;
    
    vc.targetViewController = viewController;
    vc.shouldBlurBackground = YES;
    vc.parallaxEnabled = YES;
    vc.shouldDismissOnTap = YES;
    vc.shouldDismissOnImageTap = NO;
    vc.shouldShowPhotoActions = NO;
    vc.shouldRotateToDeviceOrientation = YES;
    vc.shouldHideStatusBar = YES;
    vc.respondsToTap = YES;
    
    return vc;
}


+ (instancetype)new
{
    return [self.class enhanceUsingViewController:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setup];
}


- (void)setup
{
    _hasLaidOut = NO;
    _unhideStatusBarOnDismiss = YES;
    
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:__overlayAlpha];
    
    self.imageView.layer.allowsEdgeAntialiasing = YES;
    
    [self.imageView addGestureRecognizer:self.doubleTapRecognizer];
    [self.tapRecognizer requireGestureRecognizerToFail:self.doubleTapRecognizer];
    [self.view addGestureRecognizer:self.tapRecognizer];
    
    if (self.shouldShowPhotoActions)
    {
        [self.imageView addGestureRecognizer:self.photoLongPressRecognizer];
    }
    
    [self.imageView addGestureRecognizer:self.panRecognizer];
    
    /* UIDynamics stuff */
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator.delegate = self;
    
    // snap behavior to keep image view in the center as needed
    self.snapBehavior = [[UISnapBehavior alloc] initWithItem:self.imageView snapToPoint:self.view.center];
    self.snapBehavior.damping = 1.0f;
    
    self.pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.imageView] mode:UIPushBehaviorModeInstantaneous];
    self.pushBehavior.angle = 0.0f;
    self.pushBehavior.magnitude = 0.0f;
    
    self.itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.imageView]];
    self.itemBehavior.elasticity = 0.0f;
    self.itemBehavior.friction = 0.2f;
    self.itemBehavior.allowsRotation = YES;
    self.itemBehavior.density = __density;
    self.itemBehavior.resistance = __resistance;
}

- (void)cancelURLConnectionIfAny {
    if (self.loadingView) {
        [self.loadingView stopAnimating];
        if (self.loadingView.superview) [self.loadingView removeFromSuperview];
    }
    if (self.urlConnection) [self.urlConnection cancel];
};

#pragma mark - Presenting and Dismissing

- (void)showImage:(UIImage *)image fromView:(UIView *)fromView {
    [self showImage:image fromView:fromView inViewController:nil];
}

- (void)showImage:(UIImage *)image fromView:(UIView *)fromView inViewController:(UIViewController *)parentViewController {
    self.fromView = fromView;
    UIView *superview = (parentViewController) ? parentViewController.view : fromView.superview;
    CGRect fromRect = [superview convertRect:fromView.frame toView:nil];
    
    [self showImage:image fromRect:fromRect];
}

- (void)showImage:(UIImage *)image fromRect:(CGRect)fromRect {
    NSAssert(image, @"Image is required");
    
    [self view]; // make sure view has loaded first
    CGRect bounds = self.keyWindow.bounds;
    self.view.frame = bounds;
    
    self.fromRect = fromRect;
    
    self.imageView.transform = CGAffineTransformIdentity;
    self.imageView.image = image;
    self.imageView.alpha = 0.2;
    
    // create snapshot of background if parallax is enabled
    if (self.parallaxEnabled || self.shouldBlurBackground) {
        [self createViewsForBackground];
    }
    
    if (self.shouldHideStatusBar)
    {
        // hide status bar, but store whether or not we need to unhide it later when dismissing this view
        // NOTE: in iOS 7+, this only works if you set `UIViewControllerBasedStatusBarAppearance` to YES in your Info.plist
        _unhideStatusBarOnDismiss = ![UIApplication sharedApplication].statusBarHidden;
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
        
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
            [self setNeedsStatusBarAppearanceUpdate];
        }
    }
    
    // update scrollView.contentSize to the size of the image
    self.scrollView.contentSize = image.size;
    CGFloat scaleWidth = CGRectGetWidth(self.scrollView.frame) / self.scrollView.contentSize.width;
    CGFloat scaleHeight = CGRectGetHeight(self.scrollView.frame) / self.scrollView.contentSize.height;
    CGFloat scale = MIN(scaleWidth, scaleHeight);
    
    // image view's destination frame is the size of the image capped to the width/height of the target view
    CGPoint midpoint = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    CGSize scaledImageSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
    CGRect targetRect = CGRectMake(midpoint.x - scaledImageSize.width / 2.0, midpoint.y - scaledImageSize.height / 2.0, scaledImageSize.width, scaledImageSize.height);
    
    // set initial frame of image view to match that of the presenting image
    self.imageView.frame = [self.view convertRect:fromRect fromView:nil];
    _originalFrame = targetRect;
    
    if (scale < 1.0f) {
        self.scrollView.minimumZoomScale = 1.0f;
        self.scrollView.maximumZoomScale = 1.0f / scale;
    }
    else {
        self.scrollView.minimumZoomScale = 1.0f / scale;
        self.scrollView.maximumZoomScale = 1.0f;
    }
    
    _minScale = self.scrollView.minimumZoomScale;
    _maxScale = self.scrollView.maximumZoomScale;
    _lastPinchScale = 1.0f;
    _hasLaidOut = YES;
    
    if (self.targetViewController) {
        [self willMoveToParentViewController:self.targetViewController];
        if ([UIView instancesRespondToSelector:@selector(setTintAdjustmentMode:)]) {
            self.targetViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
            [self.targetViewController.view tintColorDidChange];
        }
        [self.targetViewController addChildViewController:self];
        [self.targetViewController.view addSubview:self.view];
        
        if (self.snapshotView) {
            [self.targetViewController.view insertSubview:self.snapshotView belowSubview:self.view];
            [self.targetViewController.view insertSubview:self.blurredSnapshotView aboveSubview:self.snapshotView];
        }
    }
    else {
        // add this view to the main window if no targetViewController was set
        if ([UIView instancesRespondToSelector:@selector(setTintAdjustmentMode:)]) {
            self.keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
            [self.keyWindow tintColorDidChange];
        }
        [self.keyWindow addSubview:self.view];
        
        if (self.snapshotView) {
            [self.keyWindow insertSubview:self.snapshotView belowSubview:self.view];
            [self.keyWindow insertSubview:self.blurredSnapshotView aboveSubview:self.snapshotView];
        }
    }
    
    [UIView animateWithDuration:__animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.backgroundView.alpha = 1.0f;
        self.imageView.alpha = 1.0f;
        self.imageView.frame = targetRect;
        
        if (self.snapshotView) {
            self.blurredSnapshotView.alpha = 1.0f;
            if (self.parallaxEnabled) {
                self.blurredSnapshotView.transform = CGAffineTransformScale(CGAffineTransformIdentity, __backgroundScale, __backgroundScale);
                self.snapshotView.transform = CGAffineTransformScale(CGAffineTransformIdentity, __backgroundScale, __backgroundScale);
            }
        }
        
    } completion:^(BOOL finished) {
        if (self.targetViewController) {
            [self didMoveToParentViewController:self.targetViewController];
        }
        
        if ([self.delegate respondsToSelector:@selector(enhanceViewControllerDidAppear:)]) {
            [self.delegate enhanceViewControllerDidAppear:self];
        }
    }];
}

- (void)showImageFromURL:(NSURL *)url fromView:(UIView *)fromView {
    [self showImageFromURL:url fromView:fromView inViewController:nil];
}

- (void)showImageFromURL:(NSURL *)url fromView:(UIView *)fromView inViewController:(UIViewController *)parentViewController {
    self.fromView = fromView;
    self.targetViewController = parentViewController;
    
    UIView *superview = (parentViewController) ? parentViewController.view : fromView.superview;
    CGRect fromRect = [superview convertRect:fromView.frame toView:nil];
    
    [self showImageFromURL:url fromRect:fromRect];
}

- (void)showImageFromURL:(NSURL *)url fromRect:(CGRect)fromRect {
    self.fromRect = fromRect;
    
    // cancel any outstanding requests if we have one
    [self cancelURLConnectionIfAny];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    if (self.requestHTTPHeaders.count > 0) {
        for (NSString *key in self.requestHTTPHeaders) {
            NSString *value = [self.requestHTTPHeaders valueForKey:key];
            [request setValue:value forHTTPHeaderField:key];
        }
    }
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    self.urlConnection = connection;
    
    // stores data as it's loaded from the request
    self.urlData = [[NSMutableData alloc] init];
    
    // show loading indicator on fromView
    if (!self.loadingView) {
        self.loadingView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30.0, 30.0)];
    }
    if (self.fromView) {
        [self.fromView addSubview:self.loadingView];
        self.loadingView.center = CGPointMake(CGRectGetWidth(self.fromView.frame) / 2.0, CGRectGetHeight(self.fromView.frame) / 2.0);
    }
    
    [self.loadingView startAnimating];
    [self.urlConnection start];
}


- (void)dismiss:(BOOL)animated {
    if (animated) {
        [self dismissToTargetView];
    }
    else {
        self.backgroundView.alpha = 0.0f;
        self.imageView.alpha = 0.0f;
        [self cleanup];
    }
}

- (void)dismissAfterPush {
    [self hideSnapshotView];
    [UIView animateWithDuration:__animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.backgroundView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self cleanup];
    }];
}

- (void)dismissToTargetView {
    [self hideSnapshotView];
    
    if (self.scrollView.zoomScale != 1.0f) {
        [self.scrollView setZoomScale:1.0f animated:NO];
    }
    
    CGRect targetFrame = [self.view convertRect:self.fromView.frame fromView:nil];
    if (!CGRectIsEmpty(self.fromRect)) {
        targetFrame = self.fromRect;
    }
    
    [UIView animateWithDuration:__animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.imageView.frame = targetFrame;
        if (!CGRectIsEmpty(self.fromRect)) {
            self.imageView.frame = self.fromRect;
        }
        else {
            self.imageView.frame = [self.view convertRect:self.fromView.frame fromView:nil];
        }
        self.backgroundView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self cleanup];
    }];
    // offset image fade out slightly than background/frame animation
    [UIView animateWithDuration:__animationDuration - 0.1 delay:0.05 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.imageView.alpha = 0.0f;
    } completion:nil];
}

#pragma mark - Private Methods

- (UIWindow *)keyWindow {
    return [UIApplication sharedApplication].keyWindow;
}

- (void)createViewsForBackground {
    // container view for window
    CGRect containerFrame = CGRectMake(0, 0, CGRectGetWidth(self.keyWindow.frame), CGRectGetHeight(self.keyWindow.frame));
    
    // inset container view so we can blur the edges, but we also need to scale up so when __backgroundScale is applied, everything lines up
    // only perform inset if `parallaxEnabled` is YES
    if (self.parallaxEnabled) {
        containerFrame.size.width *= 1.0f / __backgroundScale;
        containerFrame.size.height *= 1.0f / __backgroundScale;
    }
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectIntegral(containerFrame)];
    containerView.backgroundColor = [UIColor blackColor];
    
    // add snapshot of window to the container
    UIImage *windowSnapshot = [self.keyWindow enh_snapshotImageWithScale:[UIScreen mainScreen].scale];
    UIImageView *windowSnapshotView = [[UIImageView alloc] initWithImage:windowSnapshot];
    windowSnapshotView.center = containerView.center;
    [containerView addSubview:windowSnapshotView];
    containerView.center = self.keyWindow.center;
    
    UIImageView *snapshotView;
    // only add blurred view if radius is above 0
    if (self.shouldBlurBackground && __blurRadius) {
        UIImage *snapshot = [containerView enh_snapshotImageWithScale:[UIScreen mainScreen].scale];
        snapshot = [snapshot enh_applyBlurWithRadius:__blurRadius
                                           tintColor:[UIColor colorWithWhite:0.0f alpha:__blurTintColorAlpha]
                               saturationDeltaFactor:__blurSaturationDeltaMask
                                           maskImage:nil];
        snapshotView = [[UIImageView alloc] initWithImage:snapshot];
        snapshotView.center = containerView.center;
        snapshotView.alpha = 0.0f;
        snapshotView.userInteractionEnabled = NO;
    }
    
    self.snapshotView = containerView;
    self.blurredSnapshotView = snapshotView;
}


/**
 *	When adding UIDynamics to a view, it resets `zoomScale` on UIScrollView back to 1.0, which is an issue when applying dynamics
 *	to the imageView when scaled down. So we just scale the imageView.frame while dynamics are applied.
 */
- (void)scaleImageForDynamics {
    _lastZoomScale = self.scrollView.zoomScale;
    
    CGRect imageFrame = self.imageView.frame;
    imageFrame.size.width *= _lastZoomScale;
    imageFrame.size.height *= _lastZoomScale;
    self.imageView.frame = imageFrame;
}

- (void)centerScrollViewContents {
    CGSize contentSize = self.scrollView.contentSize;
    CGFloat offsetX = (CGRectGetWidth(self.scrollView.frame) > contentSize.width) ? (CGRectGetWidth(self.scrollView.frame) - contentSize.width) / 2.0f : 0.0f;
    CGFloat offsetY = (CGRectGetHeight(self.scrollView.frame) > contentSize.height) ? (CGRectGetHeight(self.scrollView.frame) - contentSize.height) / 2.0f : 0.0f;
    self.imageView.center = CGPointMake(self.scrollView.contentSize.width / 2.0f + offsetX, self.scrollView.contentSize.height / 2.0f + offsetY);
}

- (void)returnToCenter {
    if (self.animator) {
        [self.animator removeAllBehaviors];
    }
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.imageView.transform = CGAffineTransformIdentity;
        // TODO: Kill _originalFrame?
//        self.imageView.frame = self.fromRect;
        self.imageView.frame = _originalFrame;
    } completion:nil];
}

- (void)hideSnapshotView {
    // only unhide status bar if it wasn't hidden before this view appeared
    if (_unhideStatusBarOnDismiss) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
    
    [UIView animateWithDuration:__animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.blurredSnapshotView.alpha = 0.0f;
        self.blurredSnapshotView.transform = CGAffineTransformIdentity;
        self.snapshotView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self.snapshotView removeFromSuperview];
        [self.blurredSnapshotView removeFromSuperview];
        self.snapshotView = nil;
        self.blurredSnapshotView = nil;
    }];
}

- (void)cleanup {
    _hasLaidOut = NO;
    [self.view removeFromSuperview];
    
    if (self.targetViewController) {
        if ([UIView instancesRespondToSelector:@selector(setTintAdjustmentMode:)]) {
            self.targetViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            [self.targetViewController.view tintColorDidChange];
        }
        [self willMoveToParentViewController:nil];
        [self removeFromParentViewController];
    }
    else {
        if ([UIWindow instancesRespondToSelector:@selector(setTintAdjustmentMode:)]) {
            self.keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            [self.keyWindow tintColorDidChange];
        }
    }
    
    if (self.animator) {
        [self.animator removeAllBehaviors];
    }
    
    if ([self.delegate respondsToSelector:@selector(enhanceViewControllerDidDisappear:)]) {
        [self.delegate enhanceViewControllerDidDisappear:self];
    }
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)saveImageToLibrary:(UIImage *)image {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                                message:error.localizedRecoverySuggestion
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedStringFromTable(@"interaction.ok", @"enhance", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];
}

- (void)copyImage:(UIImage *)image {
    [UIPasteboard generalPasteboard].image = image;
}

#pragma mark - Gesture Methods

- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    UIView *view = gestureRecognizer.view;
    CGPoint location = [gestureRecognizer locationInView:self.view];
    CGPoint boxLocation = [gestureRecognizer locationInView:self.imageView];
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self.animator removeBehavior:self.snapBehavior];
        [self.animator removeBehavior:self.pushBehavior];
        
        UIOffset centerOffset = UIOffsetMake(boxLocation.x - CGRectGetMidX(self.imageView.bounds), boxLocation.y - CGRectGetMidY(self.imageView.bounds));
        self.panAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.imageView offsetFromCenter:centerOffset attachedToAnchor:location];
        [self.animator addBehavior:self.panAttachmentBehavior];
        [self.animator addBehavior:self.itemBehavior];
        [self scaleImageForDynamics];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        self.panAttachmentBehavior.anchorPoint = location;
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.animator removeBehavior:self.panAttachmentBehavior];
        
        // need to scale velocity values to tame down physics on the iPad
        CGFloat deviceVelocityScale = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 0.2f : 1.0f;
        CGFloat deviceAngularScale = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 0.7f : 1.0f;
        // factor to increase delay before `dismissAfterPush` is called on iPad to account for more area to cover to disappear
        CGFloat deviceDismissDelay = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 1.8f : 1.0f;
        CGPoint velocity = [gestureRecognizer velocityInView:self.view];
        CGFloat velocityAdjust = 10.0f * deviceVelocityScale;
        
        if (fabs(velocity.x / velocityAdjust) > __minimumVelocityRequiredForPush || fabs(velocity.y / velocityAdjust) > __minimumVelocityRequiredForPush) {
            UIOffset offsetFromCenter = UIOffsetMake(boxLocation.x - CGRectGetMidX(self.imageView.bounds), boxLocation.y - CGRectGetMidY(self.imageView.bounds));
            CGFloat radius = sqrtf(powf(offsetFromCenter.horizontal, 2.0f) + powf(offsetFromCenter.vertical, 2.0f));
            CGFloat pushVelocity = sqrtf(powf(velocity.x, 2.0f) + powf(velocity.y, 2.0f));
            
            // calculate angles needed for angular velocity formula
            CGFloat velocityAngle = atan2f(velocity.y, velocity.x);
            CGFloat locationAngle = atan2f(offsetFromCenter.vertical, offsetFromCenter.horizontal);
            if (locationAngle > 0) {
                locationAngle -= M_PI * 2;
            }
            
            // angle (θ) is the angle between the push vector (V) and vector component parallel to radius, so it should always be positive
            CGFloat angle = fabsf(fabsf(velocityAngle) - fabsf(locationAngle));
            // angular velocity formula: w = (abs(V) * sin(θ)) / abs(r)
            CGFloat angularVelocity = fabsf((fabsf(pushVelocity) * sinf(angle)) / fabsf(radius));
            
            // rotation direction is dependent upon which corner was pushed relative to the center of the view
            // when velocity.y is positive, pushes to the right of center rotate clockwise, left is counterclockwise
            CGFloat direction = (location.x < view.center.x) ? -1.0f : 1.0f;
            // when y component of velocity is negative, reverse direction
            if (velocity.y < 0) { direction *= -1; }
            
            // amount of angular velocity should be relative to how close to the edge of the view the force originated
            // angular velocity is reduced the closer to the center the force is applied
            // for angular velocity: positive = clockwise, negative = counterclockwise
            CGFloat xRatioFromCenter = fabsf(offsetFromCenter.horizontal) / (CGRectGetWidth(self.imageView.frame) / 2.0f);
            CGFloat yRatioFromCetner = fabsf(offsetFromCenter.vertical) / (CGRectGetHeight(self.imageView.frame) / 2.0f);
            
            // apply device scale to angular velocity
            angularVelocity *= deviceAngularScale;
            // adjust angular velocity based on distance from center, force applied farther towards the edges gets more spin
            angularVelocity *= ((xRatioFromCenter + yRatioFromCetner) / 2.0f);
            
            [self.itemBehavior addAngularVelocity:angularVelocity * __angularVelocityFactor * direction forItem:self.imageView];
            [self.animator addBehavior:self.pushBehavior];
            self.pushBehavior.pushDirection = CGVectorMake((velocity.x / velocityAdjust) * __velocityFactor, (velocity.y / velocityAdjust) * __velocityFactor);
            self.pushBehavior.active = YES;
            
            // delay for dismissing is based on push velocity also
            CGFloat delay = __maximumDismissDelay - (pushVelocity / 10000.0f);
            [self performSelector:@selector(dismissAfterPush) withObject:nil afterDelay:(delay * deviceDismissDelay) * __velocityFactor];
        }
        else {
            [self returnToCenter];
        }
    }
}

- (IBAction)handleDoubleTapGesture:(UITapGestureRecognizer *)gestureRecognizer
{
    if (self.scrollView.zoomScale != self.scrollView.minimumZoomScale) {
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    }
    else {
        CGPoint tapPoint = [self.imageView convertPoint:[gestureRecognizer locationInView:gestureRecognizer.view] fromView:self.scrollView];
        CGFloat newZoomScale = self.scrollView.maximumZoomScale;
        
        CGFloat w = CGRectGetWidth(self.imageView.frame) / newZoomScale;
        CGFloat h = CGRectGetHeight(self.imageView.frame) / newZoomScale;
        CGRect zoomRect = CGRectMake(tapPoint.x - (w / 2.0f), tapPoint.y - (h / 2.0f), w, h);
        
        [self.scrollView zoomToRect:zoomRect animated:YES];
    }
}

- (IBAction)handleDismissFromTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if (!self.isRespondingToTaps)
    {
        self.respondsToTap = YES;
        if (self.actionMenuController.isMenuVisible)
        {
            [self.actionMenuController setMenuVisible:NO animated:YES];
        }
        return;
    }
    
    CGPoint location = [gestureRecognizer locationInView:self.view];
    
    // if we are allowing a tap anywhere to dismiss, check if we allow taps within image bounds to dismiss also
    // otherwise a tap outside image bounds will only be able to dismiss
    if (self.shouldDismissOnTap) {
        if (self.shouldDismissOnImageTap || !CGRectContainsPoint(self.imageView.frame, location)) {
            [self dismissToTargetView];
            return;
        }
    }
    
    if (self.shouldDismissOnImageTap && CGRectContainsPoint(self.imageView.frame, location)) {
        // we aren't allowing taps outside of image bounds to dismiss, but tap was detected on image view, we can dismiss
        [self dismissToTargetView];
        return;
    }
}

- (IBAction)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        CGRect rect = {
            .origin = [gestureRecognizer locationInView:gestureRecognizer.view],
            .size = {1,1}
        };
        [self.actionMenuController setTargetRect:rect inView:gestureRecognizer.view];
        [gestureRecognizer.view becomeFirstResponder];
        [self.actionMenuController update];
        [self.actionMenuController setMenuVisible:YES animated:YES];
        
        self.respondsToTap = NO;
    }
}


#pragma mark - Menu methods
- (void)handleMenuSaveImage
{
    self.respondsToTap = YES;
    [self saveImageToLibrary:self.imageView.image];
}


- (void)handleMenuCopyImage
{
    self.respondsToTap = YES;
    [self copyImage:self.imageView.image];
}


#pragma mark - UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    // zoomScale of 1.0 is always our starting point, so anything other than that we disable the pan gesture recognizer
    if (scrollView.zoomScale <= 1.0f && !scrollView.zooming) {
        if (self.panRecognizer) {
            [self.imageView addGestureRecognizer:self.panRecognizer];
        }
        scrollView.scrollEnabled = NO;
    }
    else {
        if (self.panRecognizer) {
            [self.imageView removeGestureRecognizer:self.panRecognizer];
        }
        scrollView.scrollEnabled = YES;
    }
    [self centerScrollViewContents];
}


#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    CGFloat transformScale = self.imageView.transform.a;
    BOOL shouldRecognize = transformScale > _minScale;
    
    // make sure tap and double tap gestures aren't recognized simultaneously
    shouldRecognize = shouldRecognize && !([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]);
    
    return shouldRecognize;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.urlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.loadingView stopAnimating];
    [self.loadingView removeFromSuperview];
    
    if (self.urlData) {
        NSString *urlPath = connection.currentRequest.URL.absoluteString;
        UIImage *image;
        
        // determine if the loaded url is an animated GIF, and setup accordingly if so
        if ([[urlPath substringFromIndex:[urlPath length] - 3] isEqualToString:@"gif"]) {
            self.imageView.image = [UIImage imageWithData:self.urlData];
            image = [UIImage enh_animatedImageWithAnimatedGIFData:self.urlData];
        }
        else {
            image = [UIImage imageWithData:self.urlData];
        }
        
        // sometimes the server can return bad or corrupt image data which will result in a crash if we don't throw an error here
        if (!image) {
            NSString *errorDescription = [NSString stringWithFormat:@"Bad or corrupt image data for %@", urlPath];
            NSError *error = [NSError errorWithDomain:@"com.urban10.URBMediaFocusViewController" code:100 userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
            if ([self.delegate respondsToSelector:@selector(enhanceViewController:didFailLoadingImageWithError:)]) {
                [self.delegate enhanceViewController:self didFailLoadingImageWithError:error];
            }
            return;
        }
        
        [self showImage:image fromRect:self.fromRect];
        
        if ([self.delegate respondsToSelector:@selector(enhanceViewController:didFinishLoadingImage:)]) {
            [self.delegate enhanceViewController:self didFinishLoadingImage:image];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(enhanceViewController:didFailLoadingImageWithError:)]) {
        [self.delegate enhanceViewController:self didFailLoadingImageWithError:error];
    }
}


#pragma mark - Helpers
+ (NSBundle *)enhanceBundle
{
    NSString *bundlePath = [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"enhance_resources.bundle"];
    return [NSBundle bundleWithPath:bundlePath];
}


- (UIMenuController *)actionMenuController
{
    if (_actionMenuController) return _actionMenuController;
    
    _actionMenuController = [UIMenuController sharedMenuController];
    UIMenuItem *saveItem = [UIMenuItem.alloc initWithTitle:NSLocalizedStringFromTable(@"button.save.photo", @"enhance", nil) action:@selector(handleMenuSaveImage)];
    UIMenuItem *copyItem = [UIMenuItem.alloc initWithTitle:NSLocalizedStringFromTable(@"button.copy.photo", @"enhance", nil) action:@selector(handleMenuCopyImage)];
    
    _actionMenuController.menuItems = @[saveItem, copyItem];
    
    return _actionMenuController;
}


@end
