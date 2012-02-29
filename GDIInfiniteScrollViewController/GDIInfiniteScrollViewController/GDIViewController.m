//
//  GDIViewController.m
//  GDIInfiniteScrollViewController
//
//  Created by Grant Davis on 2/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
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
    NSLog(@"view for index: %i", index);
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 100)];
    view.backgroundColor = [UIColor randomColorWithAlpha:.5];
    
    UILabel *label = [[UILabel alloc] initWithFrame:view.bounds];
    label.backgroundColor = [UIColor clearColor];
    label.text = [NSString stringWithFormat:@"View %i", index];
    [view addSubview:label];
    
    return view;
}


- (NSUInteger)numberOfViewsForInfiniteScrollViewController:(GDIInfiniteScrollViewController *)controller
{
    return 10;
}

@end
