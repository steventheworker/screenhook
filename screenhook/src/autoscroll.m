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

void overrideDefaultMiddleMouseDown(CGEventRef e) {
    
}
void overrideDefaultMiddleMouseUp(CGEventRef e) {
    
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
@end
