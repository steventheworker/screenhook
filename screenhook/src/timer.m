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
const int SIDEBARMINWIDTH = 250; // hardcoded in userChrome.css
const int RESIZER = 3; // cursor changes to resize icon <=3 pixels into a window

//vars
NSDictionary* cachedWinDict; //nonnull when sidebar forced open
BOOL ffSidebarClosed; //updates on mouseup

void ffSidebarUpdate(NSString* ff) {
    NSString* response = [helperLib runScript: [NSString stringWithFormat: @"tell application \"System Events\" to tell process \"%@\" to exists (first menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1 whose value of attribute \"AXMenuItemMarkChar\" is equal to \"✓\")", ff]];
    ffSidebarClosed = ![response isEqual: @"true"];
}

NSDictionary* FFDragInfo;
void startFFDrag(NSDictionary* winDict, NSDictionary* info, CGPoint carbonPoint) {
    FFDragInfo = @{
        @"winDict": winDict,
        @"info": info,
        @"x": @(carbonPoint.x), @"y": @(carbonPoint.y)
    };
}
void updateFFBounds(CGPoint carbonPoint) { //update window bounds
    float dX = carbonPoint.x - [FFDragInfo[@"x"] floatValue];
    float dY = carbonPoint.y - [FFDragInfo[@"y"] floatValue];
    pid_t pid = [[FFDragInfo[@"winDict"] objectForKey: (id)kCGWindowOwnerPID] intValue];
    AXUIElementRef appRef = AXUIElementCreateApplication(pid); // Get AXUIElement using PID//
    CFArrayRef windowList;
    AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, (CFTypeRef *)&windowList);
    if ((!windowList) || CFArrayGetCount(windowList) < 1) return; // originally: "continue;" (in CGwindow for loop)
    AXUIElementRef windowRef = (AXUIElementRef) CFArrayGetValueAtIndex( windowList, 0); // get just the first window for now
    CFTypeRef role;
    AXUIElementCopyAttributeValue(windowRef, kAXRoleAttribute, (CFTypeRef *)&role);
    CFTypeRef positionRef;
//    CGPoint currentPos;
//    AXUIElementCopyAttributeValue(windowRef, kAXPositionAttribute, (CFTypeRef *) &currentPos);
//    AXValueGetValue(positionRef, kAXValueCGPointType, &currentPos); // causes crash half the time (bad access)
    CGPoint newPt;
    newPt.x = [FFDragInfo[@"winDict"][@"kCGWindowBounds"][@"X"] floatValue] + dX;
    newPt.y = [FFDragInfo[@"winDict"][@"kCGWindowBounds"][@"Y"] floatValue] + dY;
    positionRef = (CFTypeRef) (AXValueCreate(kAXValueCGPointType, (const void *) &newPt));
    AXUIElementSetAttributeValue(windowRef, kAXPositionAttribute, positionRef);
}
void endFFDrag(NSDictionary* info, CGPoint carbonPoint) {
    updateFFBounds(carbonPoint);
    FFDragInfo = nil;
}

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
    
    // updateFFBounds
    if (FFDragInfo) updateFFBounds(carbonPoint);
    
    // sidebar peak
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
            //toggle sidebar
            if ((forceToggle && !ffSidebarClosed) || withinBounds) {
                if (!cachedWinDict) {
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
+ (void) mousedown: (CGEventRef) e : (CGEventType) etype {
    NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if ([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"]) {
        NSPoint mouseLocation = [NSEvent mouseLocation];
        CGPoint carbonPoint = [helperLib carbonPointFrom: mouseLocation];
        AXUIElementRef elementUnderCursor = [helperLib elementAtPoint: carbonPoint];
        NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary: [helperLib axInfo: elementUnderCursor]];
        
        NSMutableArray* wins = [helperLib getWindowsForOwnerOnScreen: [cur localizedName]];
        for (NSDictionary* winDict in wins) {
            NSDictionary* bounds = winDict[@"kCGWindowBounds"];
            if (carbonPoint.x >= [bounds[@"X"] floatValue] + RESIZER && carbonPoint.x <= [bounds[@"X"] floatValue] + [bounds[@"Width"] floatValue])
            if (carbonPoint.y >= [bounds[@"Y"] floatValue] + RESIZER && carbonPoint.y <= [bounds[@"Y"] floatValue] + 10)
                startFFDrag(winDict, info, carbonPoint);
        }
    }
}
+ (void) mouseup: (CGEventRef) e : (CGEventType) etype {
    NSPoint mouseLocation = [NSEvent mouseLocation];
    CGPoint carbonPoint = [helperLib carbonPointFrom: mouseLocation];
    AXUIElementRef elementUnderCursor = [helperLib elementAtPoint: carbonPoint];
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary: [helperLib axInfo: elementUnderCursor]];
    
    if (FFDragInfo) endFFDrag(info, carbonPoint);
        
    NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if ([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"]) {
        
    }
}
+ (void) updateFFSidebarShowing: (BOOL) val {
    if (cachedWinDict) {
        cachedWinDict = nil;
    } else ffSidebarClosed = !val;
}
+ (void) trackFrontApp: (NSNotification*) notification {
    NSRunningApplication* frontmost = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if ([[frontmost localizedName] isEqual:@"Firefox"] || [[frontmost localizedName] isEqual:@"Firefox Developer Edition"]) ffSidebarUpdate([frontmost localizedName]);
}
@end
