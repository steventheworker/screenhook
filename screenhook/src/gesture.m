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
    return self;
}
- (void) updateTouches: (NSSet<NSTouch*>*) touches : (CGEventRef) event : (CGEventType) type {
    NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
    if ((int) [touches count] == 0) {
        if ([nsEvent phase] == NSEventPhaseEnded) [self endRecognition];
    } else {
        touchCount = (int) [touches count];
        [gesture addObject: touches];
    }
}
- (void) recognizeGesture: (CGEventRef) event : (CGEventType) type {
    NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
//    NSEventType eventType = [nsEvent type];
//    if ([nsEvent phase] == NSEventPhaseEnded) {
//        NSLog(@"it has ended!!!");
//    }
    if (touchCount <= 1) return; // 1 finger gestures not supported, helps make sure only trackpad monitored
    NSArray* touches1 = [[gesture objectAtIndex: 0] allObjects];
    NSArray* touches2 = [[gesture objectAtIndex: [gesture count] - 1] allObjects];
    if (touchCount == 2) {
        // detect twoFingerSwipeFromLeftEdge
        const float r = 0.1; //todo: (firefox) if right sidebar r = 1 - r
        if ([touches2[0] normalizedPosition].x < r || ([touches2 count] == 2 && [touches2[1] normalizedPosition].x < r)) twoFingerSwipeFromLeftEdge();
        if ([touches1[0] normalizedPosition].x < r || ([touches1 count] == 2 && [touches1[1] normalizedPosition].x < r)) twoFingerSwipeFromLeftEdge();
    } else if (touchCount == 3) {
    } else if (touchCount == 4) {
    } else if (touchCount == 5) {
    }
}
- (void) endRecognition {
    gesture = [NSMutableArray new];
    touchCount = 0;
    twoFingerSwipeFromLeftEdgeTriggered = NO;
}

@end
