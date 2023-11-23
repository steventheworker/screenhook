//
//  gesture.m
//  screenhook
//
//  Created by Steven G on 11/22/23.
//

#import "gesture.h"
#import "globals.h"
#import "helperLib.h"

GestureManager* _gm; //reference to the main (and likely the only) instance of the gesture manager
BOOL twoFingerSwipeFromLeftEdgeTriggered = NO; //has gesture fired yet?
NSMutableDictionary* triggeredGestures; // prevents re-firing swipe (3-5 finger) gestures


void setTriggeredGesture(NSString* touchCount, NSString* swipeDirection) {
    [_gm resetTriggeredGestures];
    triggeredGestures[touchCount][swipeDirection] = @1;
}
/* Gesture Handlers */
/*
 2 fingers
*/
void twoFingerSwipeFromLeftEdge(void) {
    if (twoFingerSwipeFromLeftEdgeTriggered) return;
    twoFingerSwipeFromLeftEdgeTriggered = YES;
    
//    [app twoFingerSwipeFromLeftEdge];
}
/*
 3 fingers
*/
void threeFingerSwipeLeft(void) {
    if ([triggeredGestures[@"3"][@"left"] boolValue]) return;
    setTriggeredGesture(@"3", @"left");
    
//    if (!_gm->isClickSwipe) [helperLib nextSpace];
}
void threeFingerSwipeRight(void) {
    if ([triggeredGestures[@"3"][@"right"] boolValue]) return;
    setTriggeredGesture(@"3", @"right");
    
//    if (!_gm->isClickSwipe) [helperLib previousSpace];
}
void threeFingerSwipeUp(void) {
    if ([triggeredGestures[@"3"][@"up"] boolValue]) return;
    setTriggeredGesture(@"3", @"up");
    
    if (!_gm->isClickSwipe) { // mission control immediately
        [helperLib openMissionControl];
    }
}
void threeFingerSwipeDown(void) {
    if ([triggeredGestures[@"3"][@"down"] boolValue]) return;
    setTriggeredGesture(@"3", @"down");
    
    if (!_gm->isClickSwipe) [helperLib openAppExpose];
}
/*
 4 fingers
*/
void fourFingerSwipeLeft(void) {
    if ([triggeredGestures[@"4"][@"left"] boolValue]) return;
    setTriggeredGesture(@"4", @"left");
    
//    if (!_gm->isClickSwipe) [helperLib nextSpace];
}
void fourFingerSwipeRight(void) {
    if ([triggeredGestures[@"4"][@"right"] boolValue]) return;
    setTriggeredGesture(@"4", @"right");
    
//    if (!_gm->isClickSwipe) [helperLib previousSpace];
}

@implementation GestureManager
- (void) endRecognition {
    gesture = [NSMutableArray new];
    touchCount = 0;
    twoFingerSwipeFromLeftEdgeTriggered = NO;
    isClickSwipe = NO;
    [self resetTriggeredGestures];
}
- (instancetype) init {
    [self endRecognition];
    _gm = self;
//    isClickSwipe = NO;
    return self;
}
- (void) updateTouches: (NSSet<NSTouch*>*) touches : (CGEventRef) event : (CGEventType) type {
    NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
    if ([nsEvent phase] == NSEventPhaseEnded || [nsEvent phase] == NSEventPhaseCancelled) [self endRecognition];
//    if ([nsEvent phase] == NSEventPhaseBegan) {    isClickSwipe = NO;}
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
        if (touchCount == 4) fourFingerSwipeLeft();
    } else if (isSwipeRight == numTouches) {
        NSLog(@"Swipe right detected");
        if (touchCount == 2) {
            // firefox
            const float r = 0.1; //todo: (firefox) if right sidebar r = 1 - r
            if ([touches2[0] normalizedPosition].x < r || ([touches2 count] == 2 && [touches2[1] normalizedPosition].x < r)) twoFingerSwipeFromLeftEdge();
            if ([touches1[0] normalizedPosition].x < r || ([touches1 count] == 2 && [touches1[1] normalizedPosition].x < r)) twoFingerSwipeFromLeftEdge();
        }
        if (touchCount == 3) threeFingerSwipeRight();
        if (touchCount == 4) fourFingerSwipeRight();
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
//    NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
//    NSEventType eventType = [nsEvent type];
//    // phase DNE on mousedragged
//    if (eventType != NSEventTypeLeftMouseDragged) if ([nsEvent phase] == NSEventPhaseEnded || [nsEvent phase] == NSEventPhaseBegan) return; // probably not the right time to detect gesture during these phases
//    if (touchCount <= 1) return; // 1 finger gestures not supported, helps make sure only trackpad monitored
//    NSArray* touches1 = [[gesture objectAtIndex: 0] allObjects];
//    NSArray* touches2 = [[gesture objectAtIndex: [gesture count] - 1] allObjects];
}
- (void) resetTriggeredGestures {
    triggeredGestures = [NSMutableDictionary dictionaryWithDictionary: @{
        @"3": [NSMutableDictionary dictionaryWithDictionary: @{@"left": @0, @"right": @0, @"up": @0, @"down": @0,}],
        @"4": [NSMutableDictionary dictionaryWithDictionary: @{@"left": @0, @"right": @0, @"up": @0, @"down": @0,}],
        @"5": [NSMutableDictionary dictionaryWithDictionary: @{@"left": @0, @"right": @0, @"up": @0, @"down": @0,}],
    }];
    int lastIndex = (int) ([gesture count] - 1);
    if (lastIndex > -1) {
        NSSet<NSTouch*>* lastTouches = gesture[lastIndex];
        gesture = [NSMutableArray new];
        gesture[0] = lastTouches;
    }
}
- (void) setIsClickSwipe {
    if (touchCount < 2) return;
    isClickSwipe = YES;
    NSLog(@"is click swipe");
}
- (CGEventTapCallBack) allHandler: (CGEventTapProxy) proxy : (CGEventType) type : (CGEventRef) event : (void*) refcon {
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) return (CGEventTapCallBack) event;
    NSEvent* nsEvent = [NSEvent eventWithCGEvent: event];
    NSEventType eventType = [nsEvent type];
    
    if (eventType == NSEventTypeGesture) {
        [self updateTouches: [nsEvent touchesMatchingPhase: NSTouchPhaseTouching inView: nil] : event : type];
        //gestures always use NSEventTypeScrollWheel (unless: if gesture set in Settings->trackpad => NSEventTypeMagnify; else if drag style is 3 finger drag => NSEventTypeLeftMouseDragged)
    } else if (eventType == NSEventTypeScrollWheel || eventType == NSEventTypeLeftMouseDragged || eventType == NSEventTypeMagnify) {
        [self recognizeGesture: event : type];
    } else if (eventType == NSEventTypeLeftMouseDown || eventType == NSEventTypeLeftMouseUp) {
        //todo: only call, if 3 finger drag enabled (may interfere in rare case where you use external mouse and trackpad at same time???)
        if (eventType == NSEventTypeLeftMouseDown) {}  //3 finger drag triggers mousedown at the beginning/end (instead of NSEventPhaseBegan)
        else if (eventType == NSEventTypeLeftMouseUp) [self endRecognition];  //3 finger drag triggers mouseup at the end (instead of NSEventPhaseEnded)
    } else {
        if (eventType != NSEventTypePressure && eventType != NSEventTypeSystemDefined && eventType != NSEventTypeMouseMoved && eventType != NSEventTypeLeftMouseDown && eventType != NSEventTypeLeftMouseUp && // pressure = audible click (not by tap), NSEventTypeSystemDefined = tap to click
            eventType != NSEventTypeFlagsChanged && eventType != NSEventTypeKeyUp && eventType != NSEventTypeKeyDown) { // keyboard events
            NSLog(@"%lu", (unsigned long)eventType);
        }
    }
    //    if (eventType != NSEventTypeGesture && eventType != NSEventTypeMouseMoved && eventType != NSEventTypeFlagsChanged && eventType != NSEventTypeKeyUp && eventType != NSEventTypeKeyDown) NSLog(@"%lu", (unsigned long)eventType);
    
    return (CGEventTapCallBack) event;
}
+ (void) on: (NSString*) ev : (void (^)(BOOL granted))handler {return [_gm on: ev : handler];}
- (void) on: (NSString*) ev : (void (^)(BOOL granted))handler {}
@end
