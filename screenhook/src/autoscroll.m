//
//  autoscroll.m
//  screenhook
//
//  Created by Steven G on 8/18/23.
//

#import "autoscroll.h"
#import "helperLib.h"

//"config"
int autoscrollIconSize = 32;
NSArray* blacklist = @[@"com.microsoft.VSCode", @"com.microsoft.VSCodeInsiders", @"com.visualstudio.code.oss", @"com.barebones.bbedit", @"com.jetbrains.intellij", @"com.jetbrains.WebStorm", @"com.jetbrains.PhpStorm", @"com.jetbrains.rubymine", @"com.jetbrains.clion", @"com.jetbrains.goland", @"com.jetbrains.appcode", @"com.jetbrains.pycharm", /* @"com.apple.Safari", @"org.mozilla.firefoxdeveloperedition" */];BOOL isBlacklisted(NSString* appBID) {
    for (NSString *str in blacklist)
        if ([str isEqualToString: appBID]) return YES;
    return NO;
}

NSWindow* autoscrollImageWindow;
NSTimer* timerRef;
CGPoint startPoint; // start cursor position
CGPoint cur; // current cursor position
int scrollCounter = -1; //every time interval runs +1, resets on mouseup (-1 === disabled)
void (^autoscrollLoop)(NSTimer *timer) = ^(NSTimer *timer) {
    if (scrollCounter == -1) return;
    int dx = cur.x - startPoint.x;
    int dy = cur.y - startPoint.y;
    scrollCounter++;

    // Move the mouse to the startPoint coordinates
    CGPoint movePoint = CGPointMake(startPoint.x, startPoint.y);
    CGEventRef moveEvent = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, movePoint, kCGMouseButtonCenter);
    CGEventPost(kCGHIDEventTap, moveEvent);
    CFRelease(moveEvent);

    usleep(10000);  // 10ms, Wait a bit to let the mouse movement take effect

    // Create and post a scroll event at the new mouse position
    CGEventRef scrollEvent = CGEventCreateScrollWheelEvent(NULL,
                                                           kCGScrollEventUnitLine,
                                                           2, // number of wheel units (positive for forward, negative for backward)
                                                           dy / 8, // number of vertical wheel units
                                                           dx / 16, // number of horizontal wheel units,
                                                           0); // no modifier flags
    CGEventPost(kCGHIDEventTap, scrollEvent);
    CFRelease(scrollEvent);
    
    // Move the mouse to the cur coordinates
    CGPoint movePoint2 = CGPointMake(cur.x, cur.y);
    CGEventRef moveEvent2 = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, movePoint2, kCGMouseButtonCenter);
    CGEventPost(kCGHIDEventTap, moveEvent2);
    CFRelease(moveEvent2);
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
    if (!autoscrollImageWindow) return;
    cur = CGEventGetLocation(e);
    scrollCounter = 0;
    startPoint = cur;
    if (timerRef) [timerRef invalidate];
    timerRef = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:autoscrollLoop];
    //custom cursor
    [autoscrollImageWindow setIsVisible:YES];
    float convertedY = [[helperLib getMouseScreen] frame].size.height - cur.y;
    [autoscrollImageWindow setFrame: NSMakeRect(cur.x - autoscrollIconSize/2, convertedY - autoscrollIconSize/2, autoscrollIconSize, autoscrollIconSize) display: YES];
}
void overrideDefaultMiddleMouseUp(CGEventRef e) {
    if (!autoscrollImageWindow) return;
    shouldTriggerMiddleClick();
    cur = CGEventGetLocation(e);
    scrollCounter = -1; // disable autoscroll
    if (timerRef) [timerRef invalidate];
    // Restore the cursor to its default state
    [autoscrollImageWindow setIsVisible:NO];
}

@implementation autoscroll
+ (void) init {
    //create window from xib
//    autoscrollImageWindow = [[[NSWindowController alloc] initWithWindowNibName:@"autoscroll-overlay"] window];
//    [autoscrollImageWindow setLevel: NSPopUpMenuWindowLevel]; //float window
//    [autoscrollImageWindow setIgnoresMouseEvents:YES]; //allows the scroll to not be absorbed by the window
//    [autoscrollImageWindow setBackgroundColor:[NSColor clearColor]]; //transparent window background
}
+ (BOOL) mousedown: (CGEventRef) e : (CGEventType) etype {
    if (1) return YES;
    NSRunningApplication* activeApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if (isBlacklisted(activeApp.bundleIdentifier)) return YES;
    overrideDefaultMiddleMouseDown(e);
    return NO;
}
+ (BOOL) mouseup: (CGEventRef) e : (CGEventType) etype {
    if (1) return YES;
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
