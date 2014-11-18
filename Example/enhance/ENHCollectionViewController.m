//
//  ENHCollectionViewController.m
//  enhance
//
//  Created by Adam Yanalunas on 11/11/14.
//  Copyright (c) 2014 Adam Yanalunas. All rights reserved.
//


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
    [self.enhancer showImage:img fromView:cell];
}


#pragma mark - UICollectionViewDataSource methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}


#pragma mark - Properties
- (ENHViewController *)enhancer
{
    if (_enhancer) return _enhancer;
    
    _enhancer = [ENHViewController enhanceUsingViewController:self];
    _enhancer.shouldBlurBackground = YES;
    _enhancer.parallaxEnabled = YES;
    _enhancer.shouldDismissOnTap = YES;
    _enhancer.shouldDismissOnImageTap = YES;
    _enhancer.shouldShowPhotoActions = YES;
    
    return _enhancer;
}


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


@end
