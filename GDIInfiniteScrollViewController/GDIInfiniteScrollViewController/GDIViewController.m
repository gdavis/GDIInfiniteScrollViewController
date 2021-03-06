//
//  GDIViewController.m
//  GDIInfiniteScrollViewController
//
//  Created by Grant Davis on 2/29/12.
//  Copyright (c) 2012 Grant Davis Interactive, LLC. All rights reserved.
//

#import "GDIViewController.h"
#import "UIColor+GDIAdditions.h"

@implementation GDIViewController
@synthesize scrollViewController;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.scrollViewController = [[GDIInfiniteScrollViewController alloc] initWithDataSource:self];
    self.scrollViewController.delegate = self;
    self.scrollViewController.view.frame = CGRectMake(100, 400, self.view.frame.size.width-200, 100);
    [self.view addSubview:self.scrollViewController.view];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (UIView *)infiniteScrollViewController:(GDIInfiniteScrollViewController *)controller viewForIndex:(NSUInteger)index
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, controller.view.frame.size.height)];
    view.backgroundColor = [UIColor randomColorWithAlpha:.5];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    view.autoresizesSubviews = YES;
    
    UILabel *label = [[UILabel alloc] initWithFrame:view.bounds];
    label.backgroundColor = [UIColor clearColor];
    label.text = [NSString stringWithFormat:@"View %i", index];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [view addSubview:label];
    
//    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    [button setTitle:[NSString stringWithFormat:@"View %i", index] forState:UIControlStateNormal];
//    button.frame = CGRectMake(20, 20, 210, 60);
//    [button addTarget:self action:@selector(handleButtonTouch) forControlEvents:UIControlEventTouchUpInside];
//    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
//    [view addSubview:button];
    
    return view;
}

- (void)handleButtonTouch
{
    NSLog(@"button touch");
}


- (NSUInteger)numberOfViewsForInfiniteScrollViewController:(GDIInfiniteScrollViewController *)controller
{
    return 20;
}


- (void)infiniteScrollViewController:(GDIInfiniteScrollViewController *)controller didSelectViewAtIndex:(NSInteger)index
{
    NSLog(@"Selected index changed to: %@", @(index));
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

@end
