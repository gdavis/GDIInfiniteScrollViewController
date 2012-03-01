//
//  GDIInfiniteScrollViewController.m
//  GDIInfiniteScrollViewController
//
//  Created by Grant Davis on 2/29/12.
//  Copyright (c) 2012 Grant Davis Interactive, LLC. All rights reserved.
//

#import "GDIInfiniteScrollViewController.h"
#import "UIView+GDIAdditions.h"

#define kAnimationInterval 1.f/60.f

@interface GDIInfiniteScrollViewController()
@property (nonatomic) NSUInteger numberOfViews;
@property (nonatomic) CGFloat velocity;
@property (nonatomic) CGPoint lastTouchPoint;
@property (nonatomic) CGFloat currentOffset;
@property (strong, nonatomic) NSMutableArray *currentViews;
@property (nonatomic) NSUInteger indexOfLeftView;
@property (nonatomic) NSUInteger indexOfRightView;
@property (strong, nonatomic) NSTimer *decelerationTimer;

- (void)setDefaults;
- (void)setDataSourceProperties;
- (void)buildViews;

- (void)beginScrollingToNearestView;
- (void)endScrollingToNearestView;
- (void)selectViewAtPoint:(CGPoint)point;

- (void)beginDeceleration;
- (void)endDeceleration;
- (void)handleDecelerateTick;

- (void)updateVisibleViews;
- (void)scrollContentByValue:(CGFloat)value;
- (void)trackTouchPoint:(CGPoint)point;

- (NSUInteger)indexOfPrevView;
- (NSUInteger)indexOfNextView;

- (NSUInteger)adjustedCircularIndex:(NSInteger)index withCount:(NSUInteger)count;

@end


@implementation GDIInfiniteScrollViewController
@synthesize dataSource, delegate, friction;

@synthesize numberOfViews = _numberOfViews;
@synthesize velocity = _velocity;
@synthesize lastTouchPoint = _lastTouchPoint;
@synthesize currentOffset = _currentOffset;
@synthesize currentViews = _currentViews;
@synthesize indexOfLeftView = _indexOfLeftView;
@synthesize indexOfRightView = _indexOfRightView;
@synthesize decelerationTimer = _decelerationTimer;

- (id)initWithDataSource:(NSObject <GDIInfiniteScrollViewControllerDataSource> *)ds
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        dataSource = ds;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    view.autoresizesSubviews = YES;
    self.view = view;
    view.backgroundColor = [UIColor lightGrayColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

#pragma mark - Getters / Setters

- (void)setDataSource:(NSObject<GDIInfiniteScrollViewControllerDataSource> *)ds
{
    dataSource = ds;
    [self reloadData];
}


#pragma mark - Setup Methods

- (void)setDefaults
{
    _currentOffset = 0;
    _velocity = 0;
    self.friction = .95f;
}


- (void)setDataSourceProperties
{
    _numberOfViews = [dataSource numberOfViewsForInfiniteScrollViewController:self];
}


- (void)buildViews
{
    _currentViews = [NSMutableArray array];
    
    CGFloat currentWidth = 0;
    int i;
    for (i=0; i < _numberOfViews && currentWidth < self.view.frameWidth; i++) {
        
        UIView *view = [dataSource infiniteScrollViewController:self viewForIndex:i];
        view.frameLeft = currentWidth;
        currentWidth += view.frameWidth;
        [_currentViews addObject:view];
        [self.view addSubview:view];
    }
    
    self.indexOfLeftView = 0;
    self.indexOfRightView = i-1;
}


#pragma mark - Instance Methods

- (void)reloadData
{
    [self setDefaults];
    [self setDataSourceProperties];
    [self buildViews];
}


#pragma mark - Scroll Methods

- (void)scrollContentByValue:(CGFloat)value
{
    _currentOffset += value;
    
    for (UIView *view in _currentViews) {
        view.frameLeft += value;
    }
    
    [self updateVisibleViews];
}

- (void)trackTouchPoint:(CGPoint)point
{
    CGFloat delta = point.x - _lastTouchPoint.x;
    
    [self scrollContentByValue:delta];
    
    _velocity = delta;
    _lastTouchPoint = point;
}


- (void)updateVisibleViews
{
    // remove views that are too far left
    UIView *view = [_currentViews objectAtIndex:0];
    while (view.frameRight < 0) {
        
        [_currentViews removeObject:view];
        [view removeFromSuperview];
        self.indexOfLeftView = [self adjustedCircularIndex:self.indexOfLeftView+1 withCount:_numberOfViews];
        
        view = [_currentViews objectAtIndex:0];
        
        
    }
    
    // remove views that are too far right
    view = [_currentViews lastObject];
    while (view.frameLeft > self.view.frameWidth) {
        
        [_currentViews removeObject:view];
        [view removeFromSuperview];
        self.indexOfRightView = [self adjustedCircularIndex:self.indexOfRightView-1 withCount:_numberOfViews];
        
        view = [_currentViews lastObject];
    }
    
    // add views to fill the left
    view = [_currentViews objectAtIndex:0];
    while (view.frameLeft > 0) {
        
        NSUInteger viewIndex = [self indexOfPrevView];
        
        UIView *newView = [dataSource infiniteScrollViewController:self viewForIndex:viewIndex];
        newView.frameRight = view.frameLeft;
        
        [self.view addSubview:newView];
        [_currentViews insertObject:newView atIndex:0];
        
        self.indexOfLeftView = viewIndex;
        view = newView;
    }
    
    // add views to fill the right
    view = [_currentViews lastObject];
    while (view.frameRight < self.view.frameWidth) {
        
        NSUInteger viewIndex = [self indexOfNextView];
        
        UIView *newView = [dataSource infiniteScrollViewController:self viewForIndex:viewIndex];
        newView.frameLeft = view.frameRight;
        
        [self.view addSubview:newView];
        [_currentViews addObject:newView];
        
        self.indexOfRightView = viewIndex;
        view = newView;
    }
}


- (NSUInteger)indexOfPrevView
{
    return [self adjustedCircularIndex:self.indexOfLeftView - 1 withCount:_numberOfViews];
}


- (NSUInteger)indexOfNextView
{
    return [self adjustedCircularIndex:self.indexOfRightView + 1 withCount:_numberOfViews];
}


- (NSUInteger)adjustedCircularIndex:(NSInteger)index withCount:(NSUInteger)count
{
    if (index < 0) {
        index = count - 1;
    }
    if (index >= count) {
        index = 0;
    }
    return index;
}


#pragma mark - Deceleration Methods

- (void)beginDeceleration
{
    [_decelerationTimer invalidate];
    _decelerationTimer = [NSTimer scheduledTimerWithTimeInterval:kAnimationInterval target:self selector:@selector(handleDecelerateTick) userInfo:nil repeats:YES];
}

- (void)endDeceleration
{
    [_decelerationTimer invalidate];
    _decelerationTimer = nil;
}

- (void)handleDecelerateTick
{
    _velocity *= self.friction;
    
    if ( fabsf(_velocity) < .1f) {
        [self endDeceleration];
//        [self scrollToNearestRowWithAnimation:YES];
    }
    else {
        [self scrollContentByValue:_velocity];
    }
}


#pragma mark - Nearest View Methods

- (void)beginScrollingToNearestView
{
    
}


- (void)endScrollingToNearestView
{
    
}

- (void)selectViewAtPoint:(CGPoint)point
{
    
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] == 1) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self.view];
        
        // reset the last point to where we start from.
        _lastTouchPoint = point;
        _velocity = 0;
        
        [self endDeceleration];
        [self endScrollingToNearestView];
        [self trackTouchPoint:point];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{    
    if ([touches count] == 1) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self.view];
        [self trackTouchPoint:point];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] == 1) {
        
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self.view];
        
        if (fabsf(_velocity) < 1.f) {
            // tap action
            _velocity = 0.f;
            [self selectViewAtPoint:point];
        }
        else {
            // drag action
            [self beginDeceleration];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{

}


@end

