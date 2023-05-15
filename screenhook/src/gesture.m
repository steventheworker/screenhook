//
//  gesture.m
//  screenhook
//
//  Created by Steven G on 5/13/23.
//

#import "gesture.h"
#import "app.h"

void CoreDockSendNotification(CFStringRef, void*); // add CoreDock fn's

NSMutableDictionary* triggeredGestures; // prevents re-firing gestures

/* Gesture Handlers */
// 2 fingers
BOOL twoFingerSwipeFromLeftEdgeTriggered = NO; //has gesture fired yet?
void twoFingerSwipeFromLeftEdge(void) {
    if (twoFingerSwipeFromLeftEdgeTriggered) return;
    twoFingerSwipeFromLeftEdgeTriggered = YES;
    [app twoFingerSwipeFromLeftEdge];
}
// 3 fingers
void threeFingerSwipeLeft(void) {
    if ([triggeredGestures[@"3"][@"left"] boolValue]) return;
    triggeredGestures[@"3"][@"left"] = @1;
    [[[NSAppleScript alloc] initWithSource: @"tell application \"System Events\" to key code 124 using {control down}"] executeAndReturnError: nil];
}
void threeFingerSwipeRight(void) {
    if ([triggeredGestures[@"3"][@"right"] boolValue]) return;
    triggeredGestures[@"3"][@"right"] = @1;
    [[[NSAppleScript alloc] initWithSource: @"tell application \"System Events\" to key code 123 using {control down}"] executeAndReturnError: nil];
}
void threeFingerSwipeUp(void) {
    if ([triggeredGestures[@"3"][@"up"] boolValue]) return;
    triggeredGestures[@"3"][@"up"] = @1;
    CoreDockSendNotification(CFSTR("com.apple.expose.awake"), (id) nil);
}
void threeFingerSwipeDown(void) {
    if ([triggeredGestures[@"3"][@"down"] boolValue]) return;
    triggeredGestures[@"3"][@"down"] = @1;
    CoreDockSendNotification(CFSTR("com.apple.expose.front.awake"), (id) nil);
}

@implementation GestureManager
- (instancetype) init {
    [self endRecognition];
    return self;
}
- (void) updateTouches: (NSSet<NSTouch*>*) touches : (CGEventRef) event : (CGEventType) type {
    NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
    if ([nsEvent phase] == NSEventPhaseEnded || [nsEvent phase] == NSEventPhaseEnded) [self endRecognition];
    if ((int) [touches count] == 0) {} else { // sometimes touches are 0 for no reason (...but i think it's just during NSEventPhaseEnded / NSEventPhaseStarted)
        if ((int) [touches count] != touchCount) [self endRecognition]; // going from 2 to 3 to 4 to 5 fingers is different (ie. stop comparing touch states with different finger counts to decide the gesture)
        touchCount = (int) [touches count];
        [gesture addObject: touches];
        [self detectSwipeGesture];
    }
}
- (void) detectSwipeGesture { // called before recognizeGesture to make sure it has a swipeDirection
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

    const CGFloat rX = 0.15;
    const CGFloat rY = 0.25;
    int isSwipeLeft = 0;
    int isSwipeRight = 0;
    int isSwipeUp = 0;
    int isSwipeDown = 0;

    for (NSInteger i = 0; i < numTouches; i++) {
        NSTouch *touchI = [touches1 objectAtIndex:i];
        NSTouch *touchF = [touches2 objectAtIndex:i];
        
        CGFloat dX = touchF.normalizedPosition.x - touchI.normalizedPosition.x;
        CGFloat dY = touchF.normalizedPosition.y - touchI.normalizedPosition.y;
        
        if (fabs(dX) >= rX) {
            if (dX > 0) isSwipeRight++; else isSwipeLeft++;
        }
        if (fabs(dY) >= rY) {
            if (dY < 0) isSwipeDown++; else isSwipeUp++;
        }
    }

    // if all touches
    if (isSwipeLeft == numTouches) {
        NSLog(@"Swipe left detected");
        if (touchCount == 3) threeFingerSwipeLeft();
    } else if (isSwipeRight == numTouches) {
        NSLog(@"Swipe right detected");
        if (touchCount == 3) threeFingerSwipeRight();
    }
    if (isSwipeUp == numTouches) {
        NSLog(@"Swipe up detected");
        if (touchCount == 3) threeFingerSwipeUp();
    } else if (isSwipeDown == numTouches) {
        NSLog(@"Swipe down detected");
        if (touchCount == 3) threeFingerSwipeDown();
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
    
    // reset triggeredGestures
    triggeredGestures = [NSMutableDictionary dictionaryWithDictionary: @{
        @"3": [NSMutableDictionary dictionaryWithDictionary: @{@"left": @0, @"right": @0, @"up": @0, @"down": @0,}],
        @"4": [NSMutableDictionary dictionaryWithDictionary: @{@"left": @0, @"right": @0, @"up": @0, @"down": @0,}],
        @"5": [NSMutableDictionary dictionaryWithDictionary: @{@"left": @0, @"right": @0, @"up": @0, @"down": @0,}],
    }];
}

@end
