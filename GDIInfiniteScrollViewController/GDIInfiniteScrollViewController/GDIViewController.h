//
//  GDIViewController.h
//  GDIInfiniteScrollViewController
//
//  Created by Grant Davis on 2/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GDIInfiniteScrollViewController.h"

@interface GDIViewController : UIViewController <GDIInfiniteScrollViewControllerDataSource>

@property (strong, nonatomic) GDIInfiniteScrollViewController *scrollViewController;

- (void)handleButtonTouch;

@end
