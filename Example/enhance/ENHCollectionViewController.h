//
//  ENHCollectionViewController.h
//  enhance
//
//  Created by Adam Yanalunas on 11/11/14.
//  Copyright (c) 2014 Adam Yanalunas. All rights reserved.
//


#import <UIKit/UIKit.h>


@interface ENHCollectionViewController : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSArray *images;

@end
