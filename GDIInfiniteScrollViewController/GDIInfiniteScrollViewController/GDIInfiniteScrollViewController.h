//
//  GDIInfiniteScrollViewController.h
//  GDIInfiniteScrollViewController
//
//  Created by Grant Davis on 2/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GDITouchProxyView.h"

@protocol GDIInfiniteScrollViewControllerDataSource, GDIInfiniteScrollViewControllerDelegate;

@interface GDIInfiniteScrollViewController : UIViewController <GDITouchProxyViewDelegate>

@property (weak, nonatomic) NSObject <GDIInfiniteScrollViewControllerDataSource> *dataSource;
@property (weak, nonatomic) NSObject <GDIInfiniteScrollViewControllerDelegate> *delegate;

- (id)initWithDataSource:(NSObject <GDIInfiniteScrollViewControllerDataSource> *)dataSource;

- (void)reloadData;

@end


@protocol GDIInfiniteScrollViewControllerDataSource
- (UIView *)infiniteScrollViewController:(GDIInfiniteScrollViewController *)controller viewForIndex:(NSUInteger)index;
- (NSUInteger)numberOfViewsForInfiniteScrollViewController:(GDIInfiniteScrollViewController *)controller;
@end

@protocol GDIInfiniteScrollViewControllerDelegate
@end