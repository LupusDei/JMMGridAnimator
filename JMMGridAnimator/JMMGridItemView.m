//
//  JMMGridItemView.m
//  JMMGridAnimator
//
//  Created by Justin Martin on 2/16/14.
//  Copyright (c) 2014 JMM. All rights reserved.
//

#import "JMMGridItemView.h"

@implementation JMMGridItemView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    NSLog(@"animation stopped for item : %ld", self.tag);
    
    CGPoint temp = self.startPosition;
    self.startPosition = self.finalPosition;
    self.finalPosition = temp;
    temp = self.firstStep;
    self.firstStep = self.secondStep;
    self.secondStep = temp;
    
}

@end
