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
const int RESIZEAREAHEIGHT = 15; // 100% width x 15px height = startFFDrag
const int FFMAXBOTTOM = 28; // maximum y for firefox windows

//vars
int EDGERESIZEAREA = 3; // cursor changes to resize icon <=3 pixels into a window (0 in fullscreen)
NSDictionary* cachedWinDict; //nonnull when sidebar forced open
BOOL ffSidebarClosed; //updates on mouseup

void ffSidebarUpdateClosed(NSString* ff) {
    [helperLib runAppleScriptAsync: [NSString stringWithFormat: @"tell application \"System Events\" to tell process \"%@\" to exists (first menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1 whose value of attribute \"AXMenuItemMarkChar\" is equal to \"✓\")", ff] : ^(NSString* data) {
        ffSidebarClosed = ![data isEqual: @"true"];
    }];
}
void snapFFWindow(NSString* ffName) {}
void unsnapFFWindow(NSString* ffName) {}

NSDictionary* FFInitialDrag;
NSDictionary* FFDragInfo;
int coordinatesChangedDuringDragCounter = 0;
void startFFDrag(NSDictionary* winDict, NSDictionary* info, CGPoint carbonPoint) {
    FFInitialDrag = @{
        @"winDict": winDict,
        @"info": info,
        @"x": @(carbonPoint.x), @"y": @(carbonPoint.y)
    };
    FFDragInfo = FFInitialDrag;
    [[helperLib getApp]->timer timer5x];
    coordinatesChangedDuringDragCounter = 0;
}
void updateFFBounds(CGPoint carbonPoint, BOOL mouseup) { //update window bounds
    float dX = carbonPoint.x - [FFDragInfo[@"x"] floatValue];
    float dY = carbonPoint.y - [FFDragInfo[@"y"] floatValue];
    if (fabs(dX) + fabs(dY)) coordinatesChangedDuringDragCounter++;
    pid_t pid = [[FFDragInfo[@"winDict"] objectForKey: (id)kCGWindowOwnerPID] intValue];
    AXUIElementRef appRef = AXUIElementCreateApplication(pid); // Get AXUIElement using PID
    CFArrayRef windowList;
    AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, (CFTypeRef *)&windowList);
    if (!windowList) {
        NSLog(@"!winlist = %d", pid);
        return;
    }
    long unsigned int winCount = CFArrayGetCount(windowList);
    if ((!windowList) || winCount < 1) return; // originally: "continue;" (in CGwindow for loop)
    AXUIElementRef tarWin = nil;
    AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute, (void*) &tarWin);
    CFTypeRef positionRef;
    AXUIElementCopyAttributeValue(tarWin, kAXPositionAttribute, (void*) &positionRef);
    CGPoint curPt;
    AXValueGetValue(positionRef, kAXValueCGPointType, &curPt);
    
    CFTypeRef sizeRef;
    AXUIElementCopyAttributeValue(tarWin, kAXSizeAttribute, (void*) &sizeRef);
    CGSize curSize;
    AXValueGetValue(sizeRef, kAXValueCGSizeType, &curSize);
    
    float dX0 = carbonPoint.x - [FFInitialDrag[@"x"] floatValue];
    float dY0 = carbonPoint.y - [FFInitialDrag[@"y"] floatValue];
    CGPoint newPt;
    newPt.x = [FFInitialDrag[@"winDict"][@"kCGWindowBounds"][@"X"] floatValue] + dX0;
    newPt.y = [FFInitialDrag[@"winDict"][@"kCGWindowBounds"][@"Y"] floatValue] + dY0;
    float dW = curSize.width - [FFInitialDrag[@"winDict"][@"kCGWindowBounds"][@"Width"] floatValue];
    float dH = curSize.height - [FFInitialDrag[@"winDict"][@"kCGWindowBounds"][@"Height"] floatValue];
    BOOL didSizeChange = fabs(dW) + fabs(dH) > 1;
    BOOL didBoundsChangeTooMuch = fabs((curPt.x + roundf(dX)) - roundf(newPt.x)) > 1 || fabs((curPt.y + roundf(dY)) - roundf(newPt.y)) > 1;
    if (didBoundsChangeTooMuch && !didSizeChange && coordinatesChangedDuringDragCounter > 5) {
        if ((curPt.y >= [helperLib getApp]->primaryScreenHeight - FFMAXBOTTOM)) {} //todo: replace primaryScreenHeight w/ screenAtPoint(carbonPoint).height
        else if (mouseup) { //window snapped, endFFDrag()
            FFDragInfo = nil;
            [[helperLib getApp]->timer timer1x];
            snapFFWindow(FFInitialDrag[@"winDict"][@"kCGWindowOwnerName"]); //by bounds
            return;
        }
    }
    FFDragInfo = @{
        @"winDict": @{
            @"kCGWindowBounds": @{
                @"Width": @(curSize.width),
                @"Height": @(curSize.height),
                @"X": @(curPt.x),
                @"Y": @(curPt.y)
            },
            @"kCGWindowOwnerPID": @(pid),
            @"kCGWindowOwnerName": FFInitialDrag[@"winDict"][@"kCGWindowOwnerName"],
        },
        @"info": FFDragInfo[@"info"],
        @"x": @(carbonPoint.x), @"y": @(carbonPoint.y)
    };
    if (didSizeChange) {
        if (coordinatesChangedDuringDragCounter <= 5) { //unsnap window
            FFInitialDrag = FFDragInfo;
            unsnapFFWindow(FFInitialDrag[@"winDict"][@"kCGWindowOwnerName"]);
        } else { //window snapped, endFFDrag()
            FFDragInfo = nil;
            [[helperLib getApp]->timer timer1x];
            snapFFWindow(FFInitialDrag[@"winDict"][@"kCGWindowOwnerName"]); //by resize
            return;
        }
    }
    positionRef = (CFTypeRef) (AXValueCreate(kAXValueCGPointType, (const void *) &newPt));
    AXUIElementSetAttributeValue(tarWin, kAXPositionAttribute, positionRef);
}
void endFFDrag(NSDictionary* info, CGPoint carbonPoint) {
    updateFFBounds(carbonPoint, YES);
    ffSidebarUpdateClosed(FFInitialDrag[@"winDict"][@"kCGWindowOwnerName"]);
    FFDragInfo = nil;
    [[helperLib getApp]->timer timer1x];
}

@implementation timer
+ (void) initialize {[[[timer alloc] init] timer1x];}
- (void) timerTick: (NSTimer * _Nonnull) t {
    NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
    NSPoint mouseLocation = [NSEvent mouseLocation];
    CGPoint carbonPoint = [helperLib carbonPointFrom: mouseLocation];
    AXUIElementRef elementUnderCursor = [helperLib elementAtPoint: carbonPoint];
    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary: [helperLib axInfo: elementUnderCursor]]; //axTitle, axIsApplicationRunning, axPID, axIsAPplicationRunning
    
    // updateFFBounds
    if (FFDragInfo) updateFFBounds(carbonPoint, NO);
    
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
    BOOL rightBtn = (etype == kCGEventRightMouseDown);
    if (rightBtn) {} else {
        NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
        if ([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"]) {
            NSPoint mouseLocation = [NSEvent mouseLocation];
            CGPoint carbonPoint = [helperLib carbonPointFrom: mouseLocation];
            AXUIElementRef elementUnderCursor = [helperLib elementAtPoint: carbonPoint];
            NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary: [helperLib axInfo: elementUnderCursor]];
            
            if ([info[@"role"] isEqual: @"AXButton"]) return; // ignore traffic light buttons
            NSMutableArray* wins = [helperLib getWindowsForOwnerOnScreen: [cur localizedName]];
            for (NSDictionary* winDict in wins) {
                NSDictionary* bounds = winDict[@"kCGWindowBounds"];
                if (![winDict[@"kCGWindowName"] isEqual: @"Picture-in-Picture"]) {
                    if (carbonPoint.x >= [bounds[@"X"] floatValue] && carbonPoint.x <= [bounds[@"X"] floatValue] + 10) {
                        if (carbonPoint.y >= [bounds[@"Y"] floatValue] && carbonPoint.y <= [bounds[@"Y"] floatValue] + [bounds[@"Height"] floatValue]) {
                            BOOL curState = ![[helperLib runScript: [NSString stringWithFormat: @"tell application \"System Events\" to tell process \"%@\" to exists (first menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1 whose value of attribute \"AXMenuItemMarkChar\" is equal to \"✓\")", [cur localizedName]]] isEqual: @"true"];
                            if (cachedWinDict && curState) [helperLib runScript: [NSString stringWithFormat:@"tell application \"System Events\" to tell process \"%@\" to tell (last menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1) to perform action \"AXPress\"", [cur localizedName]]];
                            if (!cachedWinDict && curState) {
                                ffSidebarClosed =! ffSidebarClosed;
                            }
                            if (cachedWinDict && !curState) {
                                cachedWinDict = nil;
                                ffSidebarClosed =! ffSidebarClosed;
                            }
                            return;
                        }
                    }
                    if (carbonPoint.x >= [bounds[@"X"] floatValue] + EDGERESIZEAREA && carbonPoint.x <= [bounds[@"X"] floatValue] + [bounds[@"Width"] floatValue])
                        if (carbonPoint.y >= [bounds[@"Y"] floatValue] + EDGERESIZEAREA && carbonPoint.y <= [bounds[@"Y"] floatValue] + RESIZEAREAHEIGHT)
                            startFFDrag(winDict, info, carbonPoint);
                }
            }
        }
    }
}
+ (void) mouseup: (CGEventRef) e : (CGEventType) etype {
    BOOL rightBtn = (etype == kCGEventRightMouseDown);
    if (rightBtn) {} else {
        NSPoint mouseLocation = [NSEvent mouseLocation];
        CGPoint carbonPoint = [helperLib carbonPointFrom: mouseLocation];
        AXUIElementRef elementUnderCursor = [helperLib elementAtPoint: carbonPoint];
        NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary: [helperLib axInfo: elementUnderCursor]];
        
        if (FFDragInfo) endFFDrag(info, carbonPoint);
        
        NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
        if ([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"]) {
            
        }
    }
}
+ (void) updateFFSidebarShowing: (BOOL) val {
    if (cachedWinDict) {
        cachedWinDict = nil;
    } else ffSidebarClosed = !val;
}
+ (void) trackFrontApp: (NSNotification*) notification {
    NSRunningApplication* frontmost = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if ([[frontmost localizedName] isEqual:@"Firefox"] || [[frontmost localizedName] isEqual:@"Firefox Developer Edition"]) ffSidebarUpdateClosed([frontmost localizedName]);
}
- (void) timer1x {
    [timerRef invalidate];
    timerRef = [NSTimer scheduledTimerWithTimeInterval: TICK_DELAY target:self selector: NSSelectorFromString(@"timerTick:") userInfo: nil repeats: YES];
    NSLog(@"timer 1x successfully started");
}
- (void) timer5x {
    [timerRef invalidate];
    timerRef = [NSTimer scheduledTimerWithTimeInterval: 0 target:self selector: NSSelectorFromString(@"timerTick:") userInfo: nil repeats: YES];
    NSLog(@"timer 2x successfully started");
}
@end
