//
//  GDIInfiniteScrollViewController.h
//  GDIInfiniteScrollViewController
//
//  Created by Grant Davis on 2/29/12.
//  Copyright (c) 2012 Grant Davis Interactive, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GDIInfiniteScrollViewControllerDataSource, GDIInfiniteScrollViewControllerDelegate;

@interface GDIInfiniteScrollViewController : UIViewController

@property (weak, nonatomic) IBOutlet id <GDIInfiniteScrollViewControllerDataSource> dataSource;
@property (weak, nonatomic) IBOutlet id <GDIInfiniteScrollViewControllerDelegate> delegate;
@property (nonatomic) CGFloat friction;
@property (assign, nonatomic) BOOL scrollsToSelectedViewCenter;
@property (assign, nonatomic) NSInteger selectedIndex; // always the view closest to center
@property (assign, nonatomic, readonly, getter=isDragging) BOOL dragging;
@property (assign, nonatomic, readonly, getter=isAnimating) BOOL animating;

- (id)initWithDataSource:(NSObject <GDIInfiniteScrollViewControllerDataSource> *)dataSource;
- (void)reloadData;

@end


@protocol GDIInfiniteScrollViewControllerDataSource <NSObject>
- (UIView *)infiniteScrollViewController:(GDIInfiniteScrollViewController *)controller viewForIndex:(NSUInteger)index;
- (NSUInteger)numberOfViewsForInfiniteScrollViewController:(GDIInfiniteScrollViewController *)controller;
@end

@protocol GDIInfiniteScrollViewControllerDelegate <NSObject>
@optional
- (void)infiniteScrollViewController:(GDIInfiniteScrollViewController *)controller didSelectViewAtIndex:(NSInteger)index;
- (void)infiniteScrollViewControllerDidScroll:(GDIInfiniteScrollViewController *)controller;
@end