//
//  timer.m
//  Dock Exposé
//
//  Created by Steven G on 4/4/23.
//

#import "timer.h"
#import "helperLib.h"
#import "globals.h"

//config
const float TICK_DELAY = ((float) 333 / 1000); // x ms / 1000 ms
const int SIDEBARMINWIDTH = 203; // actually 188 px

//vars
NSDictionary* cachedWinDict;

@implementation timer
+ (void) initialize {[[[timer alloc] init] initializer];}
- (void) initializer {
    timerRef = [NSTimer scheduledTimerWithTimeInterval: TICK_DELAY target:self selector: NSSelectorFromString(@"timerTick:") userInfo: nil repeats: YES];
    NSLog(@"timer successfully started");
}
- (void) timerTick: (NSTimer * _Nonnull) timer {
    NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
    NSPoint mouseLocation = [NSEvent mouseLocation];
    CGPoint carbonPoint = [helperLib carbonPointFrom: mouseLocation];
    AXUIElementRef elementUnderCursor = [helperLib elementAtPoint: carbonPoint];
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary: [helperLib axInfo: elementUnderCursor]]; //axTitle, axIsApplicationRunning, axPID, axIsAPplicationRunning
    if ([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"]) {
        BOOL forceToggle = NO;
        if (cachedWinDict) { // only hide sidebar when > SIDEBARMINWIDTH or < window offset
            NSDictionary* bounds = cachedWinDict[@"kCGWindowBounds"];
            if (carbonPoint.x - [bounds[@"X"] floatValue] > -2 && carbonPoint.x - [bounds[@"X"] floatValue] <= SIDEBARMINWIDTH) return;
            forceToggle = YES;
        }
        NSMutableArray* wins = [helperLib getWindowsForOwnerOnScreen: [cur localizedName]];
        for (NSDictionary* winDict in wins) {
            NSDictionary* bounds = winDict[@"kCGWindowBounds"];
            if (forceToggle || (carbonPoint.x - [bounds[@"X"] floatValue] <= 7 && carbonPoint.x >= [bounds[@"X"] floatValue])) {
                //toggle sidebar
                [helperLib runScript: [NSString stringWithFormat:@"tell application \"System Events\" to tell process \"%@\" to tell (last menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1) to perform action \"AXPress\"", [cur localizedName]]];
                if (!cachedWinDict) cachedWinDict = winDict;
                else cachedWinDict = nil;
            }
        }
        
    }
}
@end
