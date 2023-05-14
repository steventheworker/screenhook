//
//  gesture.m
//  screenhook
//
//  Created by Steven G on 5/13/23.
//

#import "gesture.h"

@implementation GestureManager
- (instancetype) init {
    [self endRecognition];
    return self;
}
- (void) updateTouches: (NSSet<NSTouch*>*) touches : (CGEventRef) event : (CGEventType) type {
    [gesture addObject: touches];
    if ((int) [touches count] == 0) {
        [self endRecognition]; //todo: only if phase == gesture ended
    } else touchCount = (int) [touches count];
}
- (void) recognizeGesture: (CGEventRef) event : (CGEventType) type {
    NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
    NSEventType eventType = [nsEvent type];
    if (eventType == NSEventTypeLeftMouseDragged && touchCount == 1) return; // 1 finger gestures not supported, helps make sure only trackpad monitored
    if (touchCount == 2) {
        NSLog(@"%d",(int) [gesture count]);
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
