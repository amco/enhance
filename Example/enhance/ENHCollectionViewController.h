//
//  ENHCollectionViewController.h
//  enhance
//
//  Created by Adam Yanalunas on 11/11/14.
//  Copyright (c) 2014 Adam Yanalunas. All rights reserved.
//


#import <enhance/enhance.h>
#import <UIKit/UIKit.h>


typedef void(^ENHMenuItemActionBlock)(void);


@interface ENHCollectionViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate, ENHViewControllerDelegate>

@property (nonatomic, strong) UIMenuController *actionMenuController;
@property (nonatomic, copy) ENHMenuItemActionBlock copyImageAction;
@property (nonatomic, strong) ENHViewController *enhancer;
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, copy) ENHMenuItemActionBlock saveImageAction;

- (void)copyImage:(UIImage *)image;
- (void)saveImageToLibrary:(UIImage *)image;

@end
