//
//  ENHCollectionViewController.m
//  enhance
//
//  Created by Adam Yanalunas on 11/11/14.
//  Copyright (c) 2014 Adam Yanalunas. All rights reserved.
//


#import <AssetsLibrary/AssetsLibrary.h>
#import "ENHCollectionViewCell.h"
#import "ENHCollectionViewController.h"


@implementation ENHCollectionViewController


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ENHCollectionViewCell *cell = (ENHCollectionViewCell *)[self.collectionView dequeueReusableCellWithReuseIdentifier:@"CellIdentifier" forIndexPath:indexPath];
    if (!cell) return nil;
    
    cell.imageView.image = self.images[indexPath.item];
    
    return cell;
}


#pragma mark - UICollectionViewDelegate methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage *img = self.images[indexPath.item];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    self.enhancer.backgroundColor = self.overlayColors[indexPath.item];
    [self.enhancer showImage:img fromView:cell];
}


#pragma mark - UICollectionViewDataSource methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}


#pragma mark - ENHViewControllerDelegate
- (void)enhanceViewController:(ENHViewController *)enhanceViewController didRegisterLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    UIImageView *imageView = (UIImageView *)gestureRecognizer.view;
    __weak typeof(self) weakSelf = self;
    
    self.copyImageAction = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [enhanceViewController allowTaps];
        [strongSelf copyImage:imageView.image];
    };
    
    self.saveImageAction = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [enhanceViewController allowTaps];
        [strongSelf saveImageToLibrary:imageView.image];
    };
    
    CGRect rect = {
        .origin = [gestureRecognizer locationInView:gestureRecognizer.view],
        .size = {1,1}
    };
    [self.actionMenuController setTargetRect:rect inView:gestureRecognizer.view];
    [gestureRecognizer.view becomeFirstResponder];
    [self.actionMenuController update];
    [self.actionMenuController setMenuVisible:YES animated:YES];
    
    [enhanceViewController preventTaps];
}


- (void)enhanceViewController:(ENHViewController *)enhanceViewController didRegisterTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded && !enhanceViewController.isRespondingToTaps)
    {
        [enhanceViewController allowTaps];
        if (self.actionMenuController.isMenuVisible)
        {
            [self.actionMenuController setMenuVisible:NO animated:YES];
        }
    }
}


#pragma mark - Menu methods
- (void)handleMenuSaveImage
{
    if (self.saveImageAction)
    {
        self.saveImageAction();
    };
}


- (void)handleMenuCopyImage
{
    if (self.copyImageAction)
    {
        self.copyImageAction();
    }
}


- (void)saveImageToLibrary:(UIImage *)image
{
    ALAssetsLibrary *library = ALAssetsLibrary.new;
    [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:error.localizedDescription
                                                                message:error.localizedRecoverySuggestion
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"interaction.ok", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];
}

- (void)copyImage:(UIImage *)image
{
    [UIPasteboard generalPasteboard].image = image;
}



#pragma mark - Properties
- (ENHViewController *)enhancer
{
    if (_enhancer) return _enhancer;
    
    _enhancer = [ENHViewController enhanceUsingViewController:self];
    _enhancer.delegate = self;
    _enhancer.shouldBlurBackground = YES;
    _enhancer.parallaxEnabled = YES;
    _enhancer.shouldDismissOnTap = YES;
    _enhancer.shouldDismissOnImageTap = YES;
    _enhancer.shouldShowPhotoActions = YES;
    
    return _enhancer;
}


#pragma mark - Properties
- (NSArray *)images
{
    if (_images) return _images;
    
    _images = @[
                [UIImage imageNamed:@"cat.jpg"],
                [UIImage imageNamed:@"computer.jpg"],
                [UIImage imageNamed:@"dog.jpg"],
                [UIImage imageNamed:@"enhance.jpg"]
                ];
    
    return _images;
}


- (NSArray *)overlayColors
{
    if (_overlayColors) return _overlayColors;
    
    _overlayColors = @[
                          [UIColor colorWithWhite:0 alpha:0.6],
                          [UIColor colorWithWhite:0 alpha:1],
                          [UIColor colorWithWhite:1 alpha:1],
                          [UIColor colorWithRed:200/255. green:10/255. blue:20/255. alpha:0.4]
                          ];
    
    return _overlayColors;
}


- (UIMenuController *)actionMenuController
{
    if (_actionMenuController) return _actionMenuController;
    
    _actionMenuController = [UIMenuController sharedMenuController];
    UIMenuItem *saveItem = [UIMenuItem.alloc initWithTitle:NSLocalizedString(@"button.save.photo", nil) action:@selector(handleMenuSaveImage)];
    UIMenuItem *copyItem = [UIMenuItem.alloc initWithTitle:NSLocalizedString(@"button.copy.photo", nil) action:@selector(handleMenuCopyImage)];
    
    _actionMenuController.menuItems = @[saveItem, copyItem];
    
    return _actionMenuController;
}


@end
