//
//  JMMViewController.m
//  JMMGridAnimator
//
//  Created by Justin Martin on 2/16/14.
//  Copyright (c) 2014 JMM. All rights reserved.
//

#import "JMMViewController.h"
#import "JMMGridItemView.h"


static CGFloat const kJMMExpansionFactor = 18.0f;
static CGFloat const kJMMJuxtapositionDuration = 2.0f;
static CGFloat const kJMMGridSize = 320.0f;
static int const kJMMItemsPerRow = 8;
static int const kJMMNumberOfRows = 8;
static CGFloat const kJMMStaggerTick = 0.02;


static CGPoint TransformAroundCenter(CGPoint center, CGPoint start) {
    return CGPointMake((center.x * 2) - start.x, (center.y * 2) - start.y);
}

static CGFloat ExpansionFromCenter(CGFloat start, CGFloat end, CGFloat length) {
    return start + ((start - end) / length) * kJMMExpansionFactor;
}

static CGPoint ExpandFromStart(CGPoint start, CGPoint end, CGSize size) {
	return CGPointMake(ExpansionFromCenter(start.x, end.x, size.width), ExpansionFromCenter(start.y, end.y, size.height));
}

static CGPoint PositionForIndex(int index, float size) {
    CGFloat xOff = size * (index % kJMMItemsPerRow);
    CGFloat yOff = size * trunc((index / kJMMItemsPerRow));
    return CGPointMake(xOff, yOff);
}


@interface JMMViewController ()
@property (nonatomic) NSMutableArray *gridItems;
@end

@implementation JMMViewController {
    NSTimer *_staggerTimer;
    UIButton *_startButton;
    CGFloat _itemSize;
    int _currentItem;
    NSMutableArray *_availablePositions;
    BOOL _swapped;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _itemSize = kJMMGridSize / kJMMItemsPerRow;
    _startButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x, self.view.height - 50, 80, 50)];
    [_startButton addTarget:self action:@selector(triggerAnimation) forControlEvents:UIControlEventTouchUpInside];
    [_startButton setTitle:@"Trigger" forState:UIControlStateNormal];
    [_startButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:_startButton];
    
    self.gridItems = [NSMutableArray array];
	for (int i = 0; i < kJMMNumberOfRows * kJMMItemsPerRow; i++) {
        [self addGridItemAtIndex:i];
    }
}

-(void) addGridItemAtIndex:(int)index {
    CGPoint position = PositionForIndex(index, _itemSize);
    JMMGridItemView *item = [[JMMGridItemView alloc] initWithFrame:CGRectMake(position.x, position.y, _itemSize, _itemSize)];
    item.tag = 1000 + index;
    item.layer.borderColor = [UIColor blackColor].CGColor;
    item.layer.borderWidth = 1;
    item.alpha = 0.4;
    CGFloat r = (arc4random() % 255);
    CGFloat g = (arc4random() % 255);
    CGFloat b = (arc4random() % 255);
    item.backgroundColor = [UIColor colorWithRed:r/255 green:g/255 blue:b/255 alpha:1];
    [self.view addSubview:item];
    [self.gridItems addObject:item];
}

-(void) setStepsForItem:(JMMGridItemView *)item forIndex:(int)index {
    item.startPosition = CGPointMake(item.center.x, item.center.y);
    CGPoint pos = PositionForIndex(index, _itemSize);
    item.finalPosition = CGPointMake(pos.x + _itemSize/2, pos.y + _itemSize/2);
    item.firstStep = ExpandFromStart(item.startPosition, item.finalPosition, CGSizeMake(self.view.width, self.view.width));
    item.secondStep = ExpandFromStart(item.finalPosition, item.startPosition, CGSizeMake(self.view.width, self.view.width));
}

-(void) setNextStepForItem:(JMMGridItemView *)item {
	int nextPosIndex = arc4random() % [_availablePositions count];
    NSNumber *nextPos = _availablePositions[nextPosIndex];
    [_availablePositions removeObjectAtIndex:nextPosIndex];
    
    [self setStepsForItem:item forIndex:nextPos.intValue];
}

-(void) resetNextSteps {
    [self resetAvailablePositions];
    for (JMMGridItemView *item in self.gridItems) {
        [self setNextStepForItem:item];
    }
}

-(void) resetAvailablePositions {
    int max = kJMMItemsPerRow * kJMMNumberOfRows;
    _availablePositions = [NSMutableArray arrayWithCapacity:kJMMItemsPerRow * kJMMNumberOfRows];
    for (int i = 0; i < max; i++) {
        [_availablePositions addObject:[NSNumber numberWithInt:i]];
    }
}

-(void) triggerAnimation {
    [self _juxtapose];
}

-(void) animationDidStart:(CAAnimation *)anim {
    
}

-(void) _juxtapose {
	if (!_staggerTimer) {
        [self resetNextSteps];
        _currentItem = 0;
        _staggerTimer = [NSTimer timerWithTimeInterval:kJMMStaggerTick target:self selector:@selector(_juxtaposeNext) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_staggerTimer forMode:NSRunLoopCommonModes];
    }
}

-(void) _juxtaposeNext {
    if (_currentItem < [self.gridItems count]) {
        [self _juxtaposeItem:self.gridItems[_currentItem]];
        _currentItem ++;
    }
    else {
        [_staggerTimer invalidate];
        _staggerTimer = nil;
    }
}

-(void) _juxtaposeItem:(JMMGridItemView *)item {
    CAKeyframeAnimation *crossAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    crossAnimation.duration = kJMMJuxtapositionDuration;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, item.startPosition.x, item.startPosition.y);
    CGPathAddLineToPoint(path, NULL, item.firstStep.x, item.firstStep.y);
    CGPathAddLineToPoint(path, NULL, item.secondStep.x, item.secondStep.y);
    CGPathAddLineToPoint(path, NULL, item.finalPosition.x, item.finalPosition.y);
    crossAnimation.path = path;
    CGPathRelease(path);
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[crossAnimation];
    group.duration = kJMMJuxtapositionDuration;
    group.fillMode = kCAFillModeForwards;
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    group.delegate = item;
    
    [item.layer addAnimation:group forKey:@"Juxtapose"];
    item.center = item.finalPosition;
}

@end


