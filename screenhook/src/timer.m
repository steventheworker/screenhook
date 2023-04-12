//
//  timer.m
//  Dock Exposé
//
//  Created by Steven G on 4/4/23.
//

#import <Cocoa/Cocoa.h>
#import "timer.h"
#import "helperLib.h"
#import "globals.h"

//config
const float TICK_DELAY = ((float) 333 / 1000); // x ms / 1000 ms
const int SIDEBARMINWIDTH = 203; // actually 188 px

//vars
NSDictionary* cachedWinDict; //nonnull when sidebar forced open
BOOL ffSidebarClosed; //updates on mouseup

@implementation timer
+ (void) initialize {[[[timer alloc] init] initializer];}
- (void) initializer {
    timerRef = [NSTimer scheduledTimerWithTimeInterval: TICK_DELAY target:self selector: NSSelectorFromString(@"timerTick:") userInfo: nil repeats: YES];
    NSLog(@"timer successfully started");
}
- (void) timerTick: (NSTimer * _Nonnull) t {
    NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
    NSPoint mouseLocation = [NSEvent mouseLocation];
    CGPoint carbonPoint = [helperLib carbonPointFrom: mouseLocation];
    AXUIElementRef elementUnderCursor = [helperLib elementAtPoint: carbonPoint];
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary: [helperLib axInfo: elementUnderCursor]]; //axTitle, axIsApplicationRunning, axPID, axIsAPplicationRunning
    if (cachedWinDict && !([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"])) cachedWinDict = nil;
    if (([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"]) && ffSidebarClosed) { //sidebar peak
        BOOL forceToggle = NO;
        if (cachedWinDict) { // only hide sidebar when > SIDEBARMINWIDTH or < window offset
            NSDictionary* bounds = cachedWinDict[@"kCGWindowBounds"];
            if (carbonPoint.x - [bounds[@"X"] floatValue] > -2 && carbonPoint.x - [bounds[@"X"] floatValue] <= SIDEBARMINWIDTH) return;
            forceToggle = YES;
        }
        NSMutableArray* wins = [helperLib getWindowsForOwnerOnScreen: [cur localizedName]];
        for (NSDictionary* winDict in wins) {
            if ([winDict[@"kCGWindowName"] isEqual: @"Picture-in-Picture"]) continue;
            NSDictionary* bounds = winDict[@"kCGWindowBounds"];
            BOOL withinBounds = (carbonPoint.x - [bounds[@"X"] floatValue] <= 7 && carbonPoint.x >= [bounds[@"X"] floatValue]);
            if ((forceToggle && !ffSidebarClosed) || withinBounds) {
                //toggle sidebar
                if (!cachedWinDict) {
//                    [timer ffSidebarUpdate: [cur localizedName]];
//                    if (!ffSidebarClosed) return;
                    cachedWinDict = winDict;
                } else cachedWinDict = nil;
                [helperLib runScript: [NSString stringWithFormat:@"tell application \"System Events\" to tell process \"%@\" to tell (last menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1) to perform action \"AXPress\"", [cur localizedName]]];
            } else if (!withinBounds && cachedWinDict) {
                cachedWinDict = nil;
                [helperLib runScript: [NSString stringWithFormat:@"tell application \"System Events\" to tell process \"%@\" to tell (last menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1) to perform action \"AXPress\"", [cur localizedName]]];
            }
            break; // only do to frontmost window (window 1), otherwise multiple toggling
        }
    }
}
+ (void) mousedown: (CGEventRef) e : (CGEventType) etype {}
+ (void) mouseup: (CGEventRef) e : (CGEventType) etype {
    NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
//    if (([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"]) && !cachedWinDict)
//        setTimeout(^{[timer ffSidebarUpdate: [cur localizedName]];}, 333);
}
+ (void) updateFFSidebarShowing: (BOOL) val {
    if (cachedWinDict) {
        cachedWinDict = nil;
    } else ffSidebarClosed = !val;
}
+ (void) ffSidebarUpdate: (NSString*) ff {
    NSString* response = [helperLib runScript: [NSString stringWithFormat: @"tell application \"System Events\" to tell process \"%@\" to exists (first menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1 whose value of attribute \"AXMenuItemMarkChar\" is equal to \"✓\")", ff]];
    ffSidebarClosed = ![response isEqual: @"true"];
}
+ (void) trackFrontApp: (NSNotification*) notification {
    NSRunningApplication* frontmost = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if ([[frontmost localizedName] isEqual:@"Firefox"] || [[frontmost localizedName] isEqual:@"Firefox Developer Edition"]) {
        [self ffSidebarUpdate: [frontmost localizedName]];
    }
}
@end
