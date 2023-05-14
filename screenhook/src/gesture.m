//
//  gesture.m
//  screenhook
//
//  Created by Steven G on 5/13/23.
//

#import "gesture.h"

void twoFingerSwipeFromLeftEdge(void) {
    NSLog(@"toggle firefox sidebar (if it's the active app)");
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
    NSEventType eventType = [nsEvent type];
//    if ([nsEvent phase] == NSEventPhaseEnded) {
//        NSLog(@"it has ended!!!");
//    }
    if (eventType == NSEventTypeLeftMouseDragged && touchCount == 1) return; // 1 finger gestures not supported, helps make sure only trackpad monitored
    if (touchCount == 2) {
        NSArray* touchesInitial = [[gesture objectAtIndex: 0] allObjects];
        NSArray* touchesFinal = [[gesture objectAtIndex: [gesture count] - 1] allObjects];
        // detect twoFingerSwipeFromLeftEdge
        const float r = 0.01; //todo: (firefox) if right sidebar r = 1 - r
        if ([touchesFinal[0] normalizedPosition].x < r || ([touchesFinal count] == 2 && [touchesFinal[1] normalizedPosition].x < r)) twoFingerSwipeFromLeftEdge();
        if ([touchesInitial[0] normalizedPosition].x < r || ([touchesInitial count] == 2 && [touchesInitial[1] normalizedPosition].x < r)) twoFingerSwipeFromLeftEdge();
    } else if (touchCount == 3) {
    } else if (touchCount == 4) {
    } else if (touchCount == 5) {
    }
}
- (void) endRecognition {
    gesture = [NSMutableArray new];
    touchCount = 0;
}

@end
