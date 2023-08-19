//
//  autoscroll.m
//  screenhook
//
//  Created by Steven G on 8/18/23.
//

#import "autoscroll.h"

NSArray* blacklist = @[@"com.microsoft.VSCode", @"org.mozilla.firefoxdeveloperedition"];
BOOL isBlacklisted(NSString* appBID) {
    for (NSString *str in blacklist)
        if ([str isEqualToString: appBID]) return YES;
    return NO;
}

CGPoint startPoint; // start cursor position
CGPoint cur; // current cursor position
int scrollCounter = -1; //every time interval runs +1, resets on mouseup (-1 === disabled)
void overrideDefaultMiddleMouseDown(CGEventRef e) {
    cur = CGEventGetLocation(e);
    scrollCounter = 0;
    startPoint = cur;
}
void overrideDefaultMiddleMouseUp(CGEventRef e) {
    cur = CGEventGetLocation(e);
    scrollCounter = -1; // disable autoscroll
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
