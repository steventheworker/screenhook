//
//  autoscroll.m
//  screenhook
//
//  Created by Steven G on 8/18/23.
//

#import "autoscroll.h"
#import "helperLib.h"

NSArray* blacklist = @[@"com.microsoft.VSCode", @"org.mozilla.firefoxdeveloperedition"];
BOOL isBlacklisted(NSString* appBID) {
    for (NSString *str in blacklist)
        if ([str isEqualToString: appBID]) return YES;
    return NO;
}

NSTimer* timerRef;
CGPoint startPoint; // start cursor position
CGPoint cur; // current cursor position
int scrollCounter = -1; //every time interval runs +1, resets on mouseup (-1 === disabled)
void (^autoscrollLoop)(NSTimer *timer) = ^(NSTimer *timer) {
    if (scrollCounter == -1) return;
    int dx = cur.x - startPoint.x;
    int dy = cur.y - startPoint.y;
    scrollCounter++;
    //scroll
    // Create a scroll event
    CGEventRef scrollEvent = CGEventCreateScrollWheelEvent(NULL,
                                                           kCGScrollEventUnitLine,
                                                           2, // number of wheel units (positive for forward, negative for backward)
                                                           dy / 8, // number of vertical wheel units
                                                           dx / 8, // number of horizontal wheel units,
                                                           0); // no modifier flags
    CGEventPost(kCGHIDEventTap, scrollEvent);
    CFRelease(scrollEvent);
};


void shouldTriggerMiddleClick(void) { // allows middle clicks to go through if intention wasn't to scroll
    int dx = cur.x - startPoint.x;
    int dy = cur.y - startPoint.y;
    if (abs(dx) + abs(dy) > 4) return; // probably intended to scroll
    if (scrollCounter > 5 && abs(dx) + abs(dy) > 2) return; // probably intended to scroll
    // Simulate a middle click
    [helperLib setSimulatedClickFlag: YES];
    CGEventPost (kCGHIDEventTap, CGEventCreateMouseEvent (NULL,kCGEventOtherMouseDown,cur,kCGMouseButtonCenter));
    CGEventPost (kCGHIDEventTap, CGEventCreateMouseEvent (NULL,kCGEventOtherMouseUp,cur,kCGMouseButtonCenter));
}

void overrideDefaultMiddleMouseDown(CGEventRef e) {
    cur = CGEventGetLocation(e);
    scrollCounter = 0;
    startPoint = cur;
    if (timerRef) [timerRef invalidate];
    timerRef = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:autoscrollLoop];
}
void overrideDefaultMiddleMouseUp(CGEventRef e) {
    shouldTriggerMiddleClick();
    cur = CGEventGetLocation(e);
    scrollCounter = -1; // disable autoscroll
    if (timerRef) [timerRef invalidate];
}

@implementation autoscroll
+ (BOOL) mousedown: (CGEventRef) e : (CGEventType) etype {
    if (etype != kCGEventOtherMouseDown) return YES;
    NSRunningApplication* activeApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if (isBlacklisted(activeApp.bundleIdentifier)) return YES;
    overrideDefaultMiddleMouseDown(e);
    return NO;
}
+ (BOOL) mouseup: (CGEventRef) e : (CGEventType) etype {
    if (etype != kCGEventOtherMouseUp) return YES;
    NSRunningApplication* activeApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if (isBlacklisted(activeApp.bundleIdentifier)) return YES;
    overrideDefaultMiddleMouseUp(e);
    return NO;
}
+ (void) mousemoved: (CGEventRef) e : (CGEventType) etype {
    if (scrollCounter == -1) return;
    cur = CGEventGetLocation(e);
}
@end
