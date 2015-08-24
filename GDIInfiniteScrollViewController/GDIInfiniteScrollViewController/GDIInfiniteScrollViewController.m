//
//  GDIInfiniteScrollViewController.m
//  GDIInfiniteScrollViewController
//
//  Created by Grant Davis on 2/29/12.
//  Copyright (c) 2012 Grant Davis Interactive, LLC. All rights reserved.
//

#import "GDIInfiniteScrollViewController.h"


static CGFloat const AnimationInterval = 1.f/60.f;
static CGFloat const Friction = 0.9f;


#pragma mark - UIVIew Additions

@interface UIView (GDIAdditions)

@property (nonatomic) CGFloat frameLeft;
@property (nonatomic) CGFloat frameRight;
@property (nonatomic) CGFloat frameBottom;
@property (nonatomic) CGFloat frameTop;
@property (nonatomic) CGFloat frameHeight;
@property (nonatomic) CGFloat frameWidth;
@property (nonatomic) CGPoint frameOrigin;

@end


#pragma mark - GDIInfiniteScrollViewController Private Interface

@interface GDIInfiniteScrollViewController()

@property (assign, nonatomic, readwrite, getter=isDragging) BOOL dragging;
@property (assign, nonatomic, readwrite, getter=isAnimating) BOOL animating;

@property (nonatomic) NSUInteger numberOfViews;
@property (nonatomic) CGFloat velocity;
@property (nonatomic) CGPoint lastTouchPoint;
@property (nonatomic) CGFloat currentOffset;
@property (strong, nonatomic) NSMutableArray *currentViews;
@property (nonatomic) NSUInteger indexOfLeftView;
@property (nonatomic) NSUInteger indexOfRightView;
@property (strong, nonatomic) NSTimer *decelerationTimer;

@property (strong, nonatomic) NSDate *moveToIndexStartTime;
@property (strong, nonatomic) NSTimer *moveToIndexTimer;
@property (nonatomic) CGFloat moveToIndexOffsetStartValue;
@property (nonatomic) CGFloat moveToIndexOffsetDelta;
@property (nonatomic) CGFloat moveToIndexOffsetDuration;

@end


#pragma mark - GDIInfiniteScrollViewController Implementation


@implementation GDIInfiniteScrollViewController


- (id)initWithDataSource:(NSObject <GDIInfiniteScrollViewControllerDataSource> *)ds
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self commonInit];
        _dataSource = ds;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}


- (void)commonInit
{
    self.scrollsToSelectedViewCenter = YES;
    self.friction = Friction;
}


#pragma mark - View lifecycle

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


#pragma mark - Getters / Setters

- (void)setDataSource:(NSObject<GDIInfiniteScrollViewControllerDataSource> *)ds
{
    _dataSource = ds;
    [self reloadData];
}


- (void)setCurrentOffset:(CGFloat)currentOffset
{
    if (_currentOffset != currentOffset) {
        _currentOffset = currentOffset;
        
        if ([self.delegate respondsToSelector:@selector(infiniteScrollViewControllerDidScroll:)]) {
            [self.delegate infiniteScrollViewControllerDidScroll:self];
        }
    }
}


#pragma mark - Setup Methods

- (void)resetState
{
    self.currentOffset = 0;
    self.velocity = 0;
}


- (void)setDataSourceProperties
{
    self.numberOfViews = [self.dataSource numberOfViewsForInfiniteScrollViewController:self];
}


- (void)buildViews
{
    self.currentViews = [NSMutableArray array];
    
    int i;
    CGFloat currentWidth = 0;
    CGFloat viewFrameWidth = CGRectGetWidth(self.view.frame);
    for (i=0; i < self.numberOfViews && currentWidth < viewFrameWidth; i++) {
        
        UIView *view = [self viewForIndex:i];
        CGRect viewFrame = view.frame;
        viewFrame.origin.x += currentWidth;
        view.frame = viewFrame;
        
        currentWidth += CGRectGetWidth(view.frame);
        [self.currentViews addObject:view];
        [self.view addSubview:view];
    }
    
    self.indexOfLeftView = 0;
    self.indexOfRightView = i-1;
}


#pragma mark - Instance Methods

- (void)reloadData
{
    [self resetState];
    [self setDataSourceProperties];
    [self buildViews];
}


#pragma mark - Scroll Methods

- (void)scrollContentByValue:(CGFloat)value
{
    self.currentOffset += value;
    
    for (UIView *view in self.currentViews) {
        view.frameLeft += value;
    }
    
    [self updateVisibleViews];
}


- (void)scrollToNearestRowWithAnimation:(BOOL)animate
{
    if (animate) {
        [self beginScrollingToNearestView];
    }
    else {
        CGPoint center = [self.view.superview convertPoint:self.view.center toView:self.view];
        UIView *closestView = [self viewClosestToCenter];
        CGFloat distance = closestView.center.x - center.x;
        [self scrollContentByValue:distance];
    }
}


- (void)trackTouchPoint:(CGPoint)point
{
    CGFloat delta = point.x - self.lastTouchPoint.x;
    
    [self scrollContentByValue:delta];
    
    self.velocity = delta;
    self.lastTouchPoint = point;
}


- (void)updateVisibleViews
{
    // remove views that are too far left
    UIView *view = [self.currentViews firstObject];
    while (view.frameRight < 0) {
        
        [self.currentViews removeObject:view];
        [view removeFromSuperview];
        self.indexOfLeftView = [self adjustedCircularIndex:self.indexOfLeftView+1 withCount:self.numberOfViews];
        
        view = [self.currentViews firstObject];
    }
    
    // remove views that are too far right
    view = [self.currentViews lastObject];
    while (view.frameLeft > self.view.frameWidth) {
        
        [self.currentViews removeObject:view];
        [view removeFromSuperview];
        self.indexOfRightView = [self adjustedCircularIndex:self.indexOfRightView-1 withCount:self.numberOfViews];
        
        view = [self.currentViews lastObject];
    }
    
    // add views to fill the left
    view = [self.currentViews firstObject];
    while (view.frameLeft > 0) {
        
        NSUInteger viewIndex = [self indexOfPrevView];
        
        UIView *newView = [self viewForIndex:viewIndex];
        newView.frameRight = view.frameLeft;
        
        [self.view addSubview:newView];
        [self.currentViews insertObject:newView atIndex:0];
        
        self.indexOfLeftView = viewIndex;
        view = newView;
    }
    
    // add views to fill the right
    view = [self.currentViews lastObject];
    while (view.frameRight < self.view.frameWidth) {
        
        NSUInteger viewIndex = [self indexOfNextView];
        
        UIView *newView = [self viewForIndex:viewIndex];
        newView.frameLeft = view.frameRight;
        
        [self.view addSubview:newView];
        [self.currentViews addObject:newView];
        
        self.indexOfRightView = viewIndex;
        view = newView;
    }
    
    [self updateSelectedIndex];
}


- (void)updateSelectedIndex
{
    if (self.isDragging || self.isAnimating) {
        return;
    }
    
    // determine what the selected index is
    UIView *viewClosestToCenter = [self viewClosestToCenter];
    if (self.selectedIndex != viewClosestToCenter.tag) {
        self.selectedIndex = viewClosestToCenter.tag;
        
        if ([self.delegate respondsToSelector:@selector(infiniteScrollViewController:didSelectViewAtIndex:)]) {
            [self.delegate infiniteScrollViewController:self didSelectViewAtIndex:self.selectedIndex];
        }
    }
}


- (UIView *)viewForIndex:(NSUInteger)index
{
    UIView *view = [self.dataSource infiniteScrollViewController:self viewForIndex:index];
    view.tag = index;
    return view;
}


- (NSUInteger)indexOfPrevView
{
    return [self adjustedCircularIndex:self.indexOfLeftView - 1 withCount:self.numberOfViews];
}


- (NSUInteger)indexOfNextView
{
    return [self adjustedCircularIndex:self.indexOfRightView + 1 withCount:self.numberOfViews];
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
    [self.decelerationTimer invalidate];
    self.decelerationTimer = [NSTimer scheduledTimerWithTimeInterval:AnimationInterval target:self selector:@selector(handleDecelerateTick) userInfo:nil repeats:YES];
}

- (void)endDeceleration
{
    [self.decelerationTimer invalidate];
    self.decelerationTimer = nil;
}

- (void)handleDecelerateTick
{
    self.velocity *= self.friction;
    
    if ( fabsf(self.velocity) < .1f) {
        [self endDeceleration];
        
        if (self.scrollsToSelectedViewCenter) {
            [self scrollToNearestRowWithAnimation:YES];
        }
    }
    else {
        [self scrollContentByValue:self.velocity];
    }
}


#pragma mark - Nearest View Methods

- (void)beginScrollingToNearestView
{
    CGPoint center = [self.view.superview convertPoint:self.view.center toView:self.view];
    UIView *closestView = [self viewClosestToCenter];
    CGFloat delta = center.x - closestView.center.x;
    
    if (fabs(delta) > 1) {
        self.velocity = 0;
        [self endDeceleration];
        [self beginScrollingWithOffsetDelta:delta];
    }
    else {
        [self scrollContentByValue:delta];
    }
}


- (void)beginScrollingWithOffsetDelta:(CGFloat)delta
{
    self.animating = YES;
    
    CGFloat targetOffset = self.currentOffset + delta;
    CGFloat currentOffset = self.currentOffset;
    
    self.moveToIndexOffsetDelta = targetOffset - currentOffset;
    self.moveToIndexOffsetStartValue = currentOffset;
    self.moveToIndexStartTime = [NSDate date];
    self.moveToIndexOffsetDuration = [[self.moveToIndexStartTime dateByAddingTimeInterval:.666f] timeIntervalSinceDate:self.moveToIndexStartTime];
    
    [self.moveToIndexTimer invalidate];
    self.moveToIndexTimer = [NSTimer scheduledTimerWithTimeInterval:AnimationInterval target:self selector:@selector(handleMoveToIndexTick) userInfo:nil repeats:YES];
}


- (void)endScrollingToNearestView
{
    [self.moveToIndexTimer invalidate];
    self.moveToIndexTimer = nil;
}


- (void)handleMoveToIndexTick
{
    CGFloat currentTime = fabs([self.moveToIndexStartTime timeIntervalSinceNow]);
    
    // stop scrolling if we are past our duration
    if (currentTime >= self.moveToIndexOffsetDuration) {
        
        self.animating = NO;
        
        [self endScrollingToNearestView];
        
        CGFloat delta = self.currentOffset - (self.moveToIndexOffsetStartValue + self.moveToIndexOffsetDelta);
        
        [self scrollContentByValue:delta];
    }
    // otherwise, calculate how much we should be scrolling our content by
    else {
        CGFloat delta = [self easeInOutWithCurrentTime:currentTime start:self.moveToIndexOffsetStartValue change:self.moveToIndexOffsetDelta duration:self.moveToIndexOffsetDuration] - self.currentOffset;
        
        [self scrollContentByValue:delta];
    }
}


#pragma mark - Easing

- (CGFloat)easeInOutWithCurrentTime:(CGFloat)t start:(CGFloat)b change:(CGFloat)c duration:(CGFloat)d
{
    if (t==0) {
        return b;
    }
    if (t==d) {
        return b+c;
    }
    if ((t/=d/2) < 1) {
        return c/2 * powf(2, 10 * (t-1)) + b;
    }
    return c/2 * (-powf(2, -10 * --t) + 2) + b;
}


#pragma mark - User Tap Selection

- (void)selectViewAtPoint:(CGPoint)point
{
    UIView *closestView = [self viewClosestToPoint:point];
    CGPoint center = [self.view.superview convertPoint:self.view.center toView:self.view];
    CGFloat delta = center.x - closestView.center.x;
    
    if (fabs(delta) > 1) {
        self.velocity = 0;
        [self endDeceleration];
        [self beginScrollingWithOffsetDelta:delta];
    }
    else {
        [self scrollContentByValue:delta];
    }
}


#pragma mark - View Finding Helpers

- (UIView *)viewClosestToCenter
{
    CGPoint center = [self.view.superview convertPoint:self.view.center toView:self.view];
    return [self viewClosestToPoint:center];
}


- (UIView *)viewClosestToPoint:(CGPoint)point
{
    UIView *closestView = nil;
    CGFloat closestViewDistanceToCenter = CGFLOAT_MAX;
    
    for (UIView *view in self.currentViews) {
        
        CGFloat deltaX = view.center.x - point.x;
        
        if (closestView == nil || fabsf(deltaX) < fabsf(closestViewDistanceToCenter)) {
            closestView = view;
            closestViewDistanceToCenter = deltaX;
        }
    }
    
    return closestView;
}


#pragma mark - Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] == 1) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self.view];
        
        self.dragging = YES;
        
        // reset the last point to where we start from.
        self.lastTouchPoint = point;
        self.velocity = 0;
        
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
        
        self.dragging = NO;
        
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self.view];
        
        if (fabsf(self.velocity) < 1.f) {
            // tap action
            self.velocity = 0.f;
            
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
    [self touchesEnded:touches withEvent:event];
}

@end



#pragma mark - UIVIew Additions


@implementation UIView (GDIAdditions)
@dynamic frameLeft;
@dynamic frameRight;
@dynamic frameBottom;
@dynamic frameTop;
@dynamic frameWidth;
@dynamic frameHeight;
@dynamic frameOrigin;

#pragma mark - Frame Accessors


- (CGFloat)frameLeft
{
    return self.frame.origin.x;
}

- (void)setFrameLeft:(CGFloat)frameLeft
{
    self.frame = CGRectMake(frameLeft, self.frameTop, self.frameWidth, self.frameHeight);
}


- (CGFloat)frameRight
{
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setFrameRight:(CGFloat)frameRight
{
    self.frame = CGRectMake(frameRight - self.frameWidth, self.frameTop, self.frameWidth, self.frameHeight);
}


- (CGFloat)frameBottom
{
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setFrameBottom:(CGFloat)frameBottom
{
    self.frame = CGRectMake(self.frameLeft, frameBottom - self.frameHeight, self.frameWidth, self.frameHeight);
}


- (CGFloat)frameTop
{
    return self.frame.origin.y;
}

- (void)setFrameTop:(CGFloat)frameTop
{
    self.frame = CGRectMake(self.frameLeft, frameTop, self.frameWidth, self.frameHeight);
}


- (CGFloat)frameWidth
{
    return self.frame.size.width;
}

- (void)setFrameWidth:(CGFloat)frameWidth
{
    self.frame = CGRectMake(self.frameLeft, self.frameTop, frameWidth, self.frameHeight);
}


- (CGFloat)frameHeight
{
    return self.frame.size.height;
}

- (void)setFrameHeight:(CGFloat)frameHeight
{
    self.frame = CGRectMake(self.frameLeft, self.frameTop, self.frameWidth, frameHeight);
}


- (CGPoint)frameOrigin
{
    return self.frame.origin;
}

- (void)setFrameOrigin:(CGPoint)frameOrigin
{
    self.frame = CGRectMake(frameOrigin.x, frameOrigin.y, self.frameWidth, self.frameHeight);
}

@end
