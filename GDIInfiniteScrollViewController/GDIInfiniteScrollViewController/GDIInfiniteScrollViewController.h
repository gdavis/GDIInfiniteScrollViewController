//
//  GDIInfiniteScrollViewController.h
//  GDIInfiniteScrollViewController
//
//  Created by Grant Davis on 2/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GDIInfiniteScrollViewControllerDataSource, GDIInfiniteScrollViewControllerDelegate;

@interface GDIInfiniteScrollViewController : UIViewController

@property (weak, nonatomic) NSObject <GDIInfiniteScrollViewControllerDataSource> *dataSource;
@property (weak, nonatomic) NSObject <GDIInfiniteScrollViewControllerDelegate> *delegate;

- (id)initWithDataSource:(NSObject <GDIInfiniteScrollViewControllerDelegate> *)dataSource;

@end


@protocol GDIInfiniteScrollViewControllerDataSource
@end

@protocol GDIInfiniteScrollViewControllerDelegate
@end