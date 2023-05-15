//
//  gesture.m
//  screenhook
//
//  Created by Steven G on 5/13/23.
//

#import "gesture.h"
#import "app.h"

BOOL twoFingerSwipeFromLeftEdgeTriggered = NO; //has gesture fired yet?
void twoFingerSwipeFromLeftEdge(void) {
    if (twoFingerSwipeFromLeftEdgeTriggered) return;
    twoFingerSwipeFromLeftEdgeTriggered = YES;
    [app twoFingerSwipeFromLeftEdge];
}

@implementation GestureManager
- (instancetype) init {
    [self endRecognition];
    swipeDirection = @"";
    return self;
}
- (void) updateTouches: (NSSet<NSTouch*>*) touches : (CGEventRef) event : (CGEventType) type {
    NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
    if ([nsEvent phase] == NSEventPhaseEnded || [nsEvent phase] == NSEventPhaseEnded) [self endRecognition];
    if ((int) [touches count] == 0) {} else { // sometimes touches are 0 for no reason (...but i think it's just during NSEventPhaseEnded / NSEventPhaseStarted)
        if ((int) [touches count] != touchCount) [self endRecognition]; // going from 2 to 3 to 4 to 5 fingers is different (ie. stop comparing touch states with different finger counts to decide the gesture)
        touchCount = (int) [touches count];
        [gesture addObject: touches];
        [self preProcessTouches];
    }
}
- (void) preProcessTouches { // called before recognizeGesture to make sure it has a swipeDirection
    NSArray *touches1 = [[gesture objectAtIndex:0 ] allObjects];
    NSArray *touches2 = [[gesture objectAtIndex: [gesture count] - 1] allObjects];
    int numTouches = (int) [touches1 count];
    if (numTouches < 2) return;

    // Sort touches1 & touches2 array based on Y-coordinate (for some reason more accurate than X)
    touches1 = [touches1 sortedArrayUsingComparator:^NSComparisonResult(NSTouch *touch1, NSTouch *touch2) {
        CGFloat x1 = touch1.normalizedPosition.y;
        CGFloat x2 = touch2.normalizedPosition.y;
        if (x1 < x2) return NSOrderedAscending;
        else if (x1 > x2) return NSOrderedDescending;
        else return NSOrderedSame;
    }];
    touches2 = [touches2 sortedArrayUsingComparator:^NSComparisonResult(NSTouch *touch1, NSTouch *touch2) {
        CGFloat x1 = touch1.normalizedPosition.y;
        CGFloat x2 = touch2.normalizedPosition.y;
        if (x1 < x2) return NSOrderedAscending;
        else if (x1 > x2) return NSOrderedDescending;
        else return NSOrderedSame;
    }];

    const CGFloat r = 0.05;
    int isSwipeLeft = 0;
    int isSwipeRight = 0;
    int isSwipeUp = 0;
    int isSwipeDown = 0;

    for (NSInteger i = 0; i < numTouches; i++) {
        NSTouch *touchI = [touches1 objectAtIndex:i];
        NSTouch *touchF = [touches2 objectAtIndex:i];
        
        CGFloat dX = touchF.normalizedPosition.x - touchI.normalizedPosition.x;
        CGFloat dY = touchF.normalizedPosition.y - touchI.normalizedPosition.y;
        
        if (fabs(dX) >= r) {
            if (dX > 0) isSwipeRight++; else isSwipeLeft++;
        }
        if (fabs(dY) >= r) {
            if (dY < 0) isSwipeDown++; else isSwipeUp++;
        }
    }

    // if all touches
    if (isSwipeLeft == numTouches) {
        NSLog(@"Swipe left detected");
    } else if (isSwipeRight == numTouches) {
        NSLog(@"Swipe right detected");
    }
    if (isSwipeUp == numTouches) {
        NSLog(@"Swipe up detected");
    } else if (isSwipeDown == numTouches) {
        NSLog(@"Swipe down detected");
    }
}
- (void) recognizeGesture: (CGEventRef) event : (CGEventType) type { //handler for NSEventTypeScrollWheel | NSEventTypeLeftMouseDragged | NSEventTypeMagnify
    NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
    NSEventType eventType = [nsEvent type];
    // phase DNE on mousedragged
    if (eventType != NSEventTypeLeftMouseDragged) if ([nsEvent phase] == NSEventPhaseEnded || [nsEvent phase] == NSEventPhaseBegan) return; // probably not the right time to detect gesture during these phases
    if (touchCount <= 1) return; // 1 finger gestures not supported, helps make sure only trackpad monitored
    NSArray* touches1 = [[gesture objectAtIndex: 0] allObjects];
    NSArray* touches2 = [[gesture objectAtIndex: [gesture count] - 1] allObjects];
    if (touchCount == 2) {
        // detect twoFingerSwipeFromLeftEdge
        const float r = 0.1; //todo: (firefox) if right sidebar r = 1 - r
        if ([touches2[0] normalizedPosition].x < r || ([touches2 count] == 2 && [touches2[1] normalizedPosition].x < r)) twoFingerSwipeFromLeftEdge();
        if ([touches1[0] normalizedPosition].x < r || ([touches1 count] == 2 && [touches1[1] normalizedPosition].x < r)) twoFingerSwipeFromLeftEdge();
    } else {
        
        
        if (touchCount == 3) {
            
        } else if (touchCount == 4) {} else if (touchCount == 5) {}
        
        
    }
}
- (void) endRecognition {
    gesture = [NSMutableArray new];
    touchCount = 0;
    twoFingerSwipeFromLeftEdgeTriggered = NO;
}

@end
