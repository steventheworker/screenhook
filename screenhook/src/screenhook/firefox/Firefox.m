//
//  Firefox.m
//  screenhook
//
//  Created by Steven G on 1/14/24.
//

#import "Firefox.h"
#import "../../helperLib.h"
#import "../../WindowManager.h"
#import "../../Spaces.h"
#import "../../helperLib.h"
#import "../../globals.h"

//config
const float SIDEBERYLONGPRESS = 0.400; // seconds
const float TICK_DELAY = ((float) 333 / 1000); // x ms / 1000 ms
const float DBLCLICKTIMEOUT = .25; // 250ms
const int SIDEBARMINWIDTH = 250; // hardcoded in userChrome.css
const int RESIZEAREAHEIGHT = 15; // 100% width x 15px height = startFFDrag
const int FFMAXBOTTOM = 28; // maximum y for firefox windows

//vars
int EDGERESIZEAREA = 3; // cursor changes to resize icon <=3 pixels into a window (0 in fullscreen)
NSDictionary* cachedWinDict; //nonnull when sidebar forced open
BOOL ffSidebarClosed; //updates on mouseup
NSTimer* doubleClickTimeout;
BOOL checkingForDblClick = NO;

//void ffSidebarUpdateClosed(NSString* ff) {
//    [helperLib runAppleScriptAsync: [NSString stringWithFormat: @"tell application \"System Events\" to tell process \"%@\" to exists (first menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1 whose value of attribute \"AXMenuItemMarkChar\" is equal to \"✓\")", ff] : ^(NSString* data) {
//        ffSidebarClosed = ![data isEqual: @"true"];
//    }];
//}
//void snapFFWindow(NSString* ffName) {}
//void unsnapFFWindow(NSString* ffName) {}
//
//void steviaOSGreenTrafficButton(void) { //run steviaOS applescript to toggle between maximized / restored window size
//    if ([steviaOSSystemFiles isEqual:@"(null)"]) return;
//    NSString *path = [NSString stringWithFormat:@"%@/green-button-click.scpt", steviaOSSystemFiles];
//    NSTask *task = [[NSTask alloc] init];
//    NSString *commandToRun = [NSString stringWithFormat:@"/usr/bin/osascript -e \'run script \"%@\"'", path];
//    NSArray *arguments = [NSArray arrayWithObjects: @"-c" , commandToRun, nil];
//    [task setLaunchPath:@"/bin/sh"];
//    [task setArguments:arguments];
//    [task launch];
//}
//
//NSDictionary* FFInitialDrag;
//NSDictionary* FFDragInfo;
//int coordinatesChangedDuringDragCounter = 0;

@implementation FFs
- (instancetype) init : (NSRunningApplication*) app {
    self = [super init];
    self->pid = app.processIdentifier;
    self->name = app.localizedName;
    self->reopenOrder = NSMutableArray.array;
    return self;
}
- (void) destroy {
    self->reopenOrder = NSMutableArray.array;
    CFRelease((__bridge CFTypeRef)(self));
}
@end

@implementation FirefoxManager
- (instancetype) init {
    self = [super init];
    self.FFs = NSMutableDictionary.dictionary;
    for (NSRunningApplication* app in NSWorkspace.sharedWorkspace.runningApplications)
        if ([app.localizedName hasPrefix: @"Firefox"]) [self initFF: app];
    //    [[[timer alloc] init] timer1x];
    //
    //    //get steviaOS info
    //    steviaOSSystemFiles = [helperLib runScript:@"tell application \"BetterTouchTool\" to get_string_variable \"steviaOSSystemFiles\""];
    //    //DockAltTab [app fullDirPath]
    //    unichar char1 = [steviaOSSystemFiles characterAtIndex:0];
    //    if ([[NSString stringWithCharacters:&char1 length:1] isEqual:@"~"]) steviaOSSystemFiles = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), [steviaOSSystemFiles substringFromIndex:1]];
    return self;
}
- (void) appTerminated: (pid_t) pid {
    [(FFs*)self.FFs[@(pid)] destroy];
}
- (void) initFF: (NSRunningApplication*) app {
    self.FFs[@(app.processIdentifier)] = [[FFs alloc] init: app];
}
- (BOOL) mousedown: (id) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos {
    mousedownEl = cursorEl;mousedownPos = cursorPos;
    FFs* ff = [self.FFs objectForKey: cursorDict[@"pid"]];
    if (!ff) return YES;
    id win = [helperLib elementDict: cursorEl : @{@"win": (id)kAXWindowAttribute}][@"win"];
    NSDictionary* winDict = [helperLib elementDict: win : @{@"pos": (id)kAXPositionAttribute, @"size": (id)kAXSizeAttribute}];
    NSRect winFrame = NSMakeRect([winDict[@"pos"][@"x"] floatValue], [winDict[@"pos"][@"y"] floatValue], [winDict[@"size"][@"width"] floatValue], [winDict[@"size"][@"height"] floatValue]);
    
    //long-press (SIDEBERY) new tab button = new window
    if ([cursorDict[@"role"] isEqual: @"AXImage"]) {
        id parent = [helperLib elementDict: cursorEl : @{@"parent": (id)kAXParentAttribute}][@"parent"];
        NSDictionary* parentDict = [helperLib elementDict: parent : @{@"role": (id)kAXRoleAttribute, @"title": (id)kAXTitleAttribute}];
        if ([parentDict[@"role"] isEqual: @"AXGroup"] && [parentDict[@"title"] isEqual: @"Open a new tab Middle click: Open a child tab"]) {
            sideberyLongPressT = NSDate.date;
            return NO;
        }
    }
    if ([cursorDict[@"role"] isEqual: @"AXGroup"] && [cursorDict[@"title"] isEqual: @"Open a new tab Middle click: Open a child tab"]) {
        sideberyLongPressT = NSDate.date;
        return NO;
    }
    
    //top edge moves window (custom Firefox CSS / titlebar-less/addressbar-less workaround)
    if (cursorPos.x >= winFrame.origin.x + EDGERESIZEAREA && cursorPos.x <= winFrame.origin.x + winFrame.size.width)
        if (cursorPos.y >= winFrame.origin.y + EDGERESIZEAREA && cursorPos.y <= winFrame.origin.y + RESIZEAREAHEIGHT)
            [self startMoving: cursorPos : win : winFrame];
    
    //click left edge toggle sidebar
    if (cursorPos.x >= winFrame.origin.x - EDGERESIZEAREA && cursorPos.x <= winFrame.origin.x + 6)
        if (cursorPos.y >= winFrame.origin.y && cursorPos.y <= winFrame.origin.y + winFrame.size.height)
            leftEdgeDown = YES;
    
    //    BOOL rightBtn = (etype == kCGEventRightMouseDown);
    //    if (rightBtn) {} else {
    //        NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
    //        if ([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"]) {
    //            NSPoint mouseLocation = [NSEvent mouseLocation];
    //            CGPoint carbonPoint = [helperLib carbonPointFrom: mouseLocation];
    //            AXUIElementRef elementUnderCursor = [helperLib elementAtPoint: carbonPoint];
    //            NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary: [helperLib axInfo: elementUnderCursor]];
    //
    //            if ([info[@"role"] isEqual: @"AXButton"]) return; // ignore traffic light buttons
    //            NSMutableArray* wins = [helperLib getWindowsForOwnerOnScreen: [cur localizedName]];
    //            for (NSDictionary* winDict in wins) {
    //                NSDictionary* bounds = winDict[@"kCGWindowBounds"];
    //                if (![winDict[@"kCGWindowName"] isEqual: @"Picture-in-Picture"]) {
    //                    //left edge
    //                    if (carbonPoint.x >= [bounds[@"X"] floatValue] && carbonPoint.x <= [bounds[@"X"] floatValue] + 10) {
    //                        if (carbonPoint.y >= [bounds[@"Y"] floatValue] && carbonPoint.y <= [bounds[@"Y"] floatValue] + [bounds[@"Height"] floatValue]) {
    //                            BOOL curState = ![[helperLib runScript: [NSString stringWithFormat: @"tell application \"System Events\" to tell process \"%@\" to exists (first menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1 whose value of attribute \"AXMenuItemMarkChar\" is equal to \"✓\")", [cur localizedName]]] isEqual: @"true"];
    //                            if (cachedWinDict && curState) [helperLib runScript: [NSString stringWithFormat:@"tell application \"System Events\" to tell process \"%@\" to tell (last menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1) to perform action \"AXPress\"", [cur localizedName]]];
    //                            if (!cachedWinDict && curState) {
    //                                ffSidebarClosed =! ffSidebarClosed;
    //                            }
    //                            if (cachedWinDict && !curState) {
    //                                cachedWinDict = nil;
    //                                ffSidebarClosed =! ffSidebarClosed;
    //                            }
    //                            return;
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //    }

    return YES;
}
- (BOOL) mouseup: (id) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos {
    setTimeout(^{self->leftEdgeDown = NO;}, 0);
    FFs* ff = [self.FFs objectForKey: cursorDict[@"pid"]];
    if (!ff) return YES;

    [self stopMoving: cursorPos];
    
    //long-press (SIDEBERY) new tab button = new window
    float dt = [NSDate.date timeIntervalSinceDate: sideberyLongPressT];
    if (dt < 0.666*2 && CFEqual((AXUIElementRef)cursorEl, (AXUIElementRef)mousedownEl)) {
        if (dt > SIDEBERYLONGPRESS) { //new window
            [helperLib applescriptAsync: @"tell application \"System Events\" to keystroke \"n\" using {command down}" : ^(NSString* res) {}];
        } else { //new tab
            [helperLib applescriptAsync: @"tell application \"System Events\" to keystroke \"t\" using {command down}" : ^(NSString* res) {}];
        }
        return NO;
    }
    
    //click left edge toggle sidebar
    if (leftEdgeDown && CGPointEqualToPoint(cursorPos, mousedownPos))
//        NSLog(@"%@", [NSString stringWithFormat:@"tell application \"System Events\" to tell process \"%@\" to tell (last menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1) to perform action \"AXPress\"", ff->name]);
        [helperLib applescriptAsync: [NSString stringWithFormat:@"tell application \"System Events\" to tell process \"%@\" to tell (last menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1) to perform action \"AXPress\"", ff->name]
                                   : ^(NSString* response) {}];
    

    //    BOOL rightBtn = (etype == kCGEventRightMouseDown);
    //    if (rightBtn) {} else {
    //        NSPoint mouseLocation = [NSEvent mouseLocation];
    //        CGPoint carbonPoint = [helperLib carbonPointFrom: mouseLocation];
    //        AXUIElementRef elementUnderCursor = [helperLib elementAtPoint: carbonPoint];
    //        NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary: [helperLib axInfo: elementUnderCursor]];
    //
    //        if (FFDragInfo) endFFDrag(info, carbonPoint);
    //
    //        NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
    //        if ([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"]) {
    //
    //        }
    //    }
    return YES;
}
- (void) mousemove: (CGPoint) cursorPos : (BOOL) isDragging {
    //    NSRunningApplication* cur = [[NSWorkspace sharedWorkspace] frontmostApplication];
    //    NSPoint mouseLocation = [NSEvent mouseLocation];
    //    CGPoint carbonPoint = [helperLib carbonPointFrom: mouseLocation];
    //    AXUIElementRef elementUnderCursor = [helperLib elementAtPoint: carbonPoint];
    //    NSMutableDictionary* info = [NSMutableDictionary dictionaryWithDictionary: [helperLib axInfo: elementUnderCursor]]; //axTitle, axIsApplicationRunning, axPID, axIsAPplicationRunning
    //    //
    //    // sidebar peak
    //    if (cachedWinDict && !([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"])) cachedWinDict = nil;
    //    if (([[cur localizedName] isEqual:@"Firefox"] || [[cur localizedName] isEqual:@"Firefox Developer Edition"]) && ffSidebarClosed) { //sidebar peak
    //        BOOL forceToggle = NO;
    //        if (cachedWinDict) { // only hide sidebar when > SIDEBARMINWIDTH or < window offset
    //            NSDictionary* bounds = cachedWinDict[@"kCGWindowBounds"];
    //            if (carbonPoint.x - [bounds[@"X"] floatValue] > -2 && carbonPoint.x - [bounds[@"X"] floatValue] <= SIDEBARMINWIDTH) return;
    //            forceToggle = YES;
    //        }
    //        NSMutableArray* wins = [helperLib getWindowsForOwnerOnScreen: [cur localizedName]];
    //        for (NSDictionary* winDict in wins) {
    //            if ([winDict[@"kCGWindowName"] isEqual: @"Picture-in-Picture"]) continue;
    //            NSDictionary* bounds = winDict[@"kCGWindowBounds"];
    //            BOOL withinBounds = (carbonPoint.x - [bounds[@"X"] floatValue] <= 7 && carbonPoint.x >= [bounds[@"X"] floatValue]);
    //            //toggle sidebar
    //            if ((forceToggle && !ffSidebarClosed) || withinBounds) {
    //                if (!cachedWinDict) {
    //                    cachedWinDict = winDict;
    //                } else cachedWinDict = nil;
    //                [helperLib runScript: [NSString stringWithFormat:@"tell application \"System Events\" to tell process \"%@\" to tell (last menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1) to perform action \"AXPress\"", [cur localizedName]]];
    //            } else if (!withinBounds && cachedWinDict) {
    //                cachedWinDict = nil;
    //                [helperLib runScript: [NSString stringWithFormat:@"tell application \"System Events\" to tell process \"%@\" to tell (last menu item of menu 1 of menu item \"Sidebar\" of menu 1 of menu bar item \"View\" of menu bar 1) to perform action \"AXPress\"", [cur localizedName]]];
    //            }
    //            break; // only do to frontmost window (window 1), otherwise multiple toggling
    //        }
    //    }

    if (startedMoving) [self updateWindowBounds: cursorPos : NO];
}

- (void) stopMoving: (CGPoint) cursorPos {
    if (startedMoving) [self updateWindowBounds: cursorPos : YES];
    startedMoving = NO;
    //    ffSidebarUpdateClosed(FFInitialDrag[@"winDict"][@"kCGWindowOwnerName"]);
    //    FFDragInfo = nil;
    //    [[helperLib getApp]->timer timer1x];
}
- (void) updateWindowBounds: (CGPoint) cursorPos : (BOOL) mouseup {
    float dx = cursorPos.x - mousedownPos.x;
    float dy = cursorPos.y - mousedownPos.y;
    NSDictionary* winDict = [helperLib elementDict: moveWindow : @{@"pos": (id)kAXPositionAttribute, @"size": (id)kAXSizeAttribute}];
    NSRect curFrame = NSMakeRect([winDict[@"pos"][@"x"] floatValue], [winDict[@"pos"][@"y"] floatValue], [winDict[@"size"][@"width"] floatValue], [winDict[@"size"][@"height"] floatValue]);
    //    float dw = curSize.width - [FFInitialDrag[@"winDict"][@"kCGWindowBounds"][@"Width"] floatValue];
    //    float dh = curSize.height - [FFInitialDrag[@"winDict"][@"kCGWindowBounds"][@"Height"] floatValue];
    CGPoint newOrigin = CGPointMake(startFrame.origin.x + dx, startFrame.origin.y + dy);
    //    BOOL didSizeChange = fabs(dW) + fabs(dH) > 1;
    //    BOOL didBoundsChangeTooMuch = fabs((curPt.x + roundf(dX)) - roundf(newPt.x)) > 1 || fabs((curPt.y + roundf(dY)) - roundf(newPt.y)) > 1;
    //    if (didBoundsChangeTooMuch && !didSizeChange && coordinatesChangedDuringDragCounter > 5) {
    //        if ((curPt.y >= [helperLib getApp]->primaryScreenHeight - FFMAXBOTTOM)) {} //todo: replace primaryScreenHeight w/ screenAtPoint(carbonPoint).height
    //        else if (mouseup) { //window snapped, endFFDrag()
    //            FFDragInfo = nil;
    //            [[helperLib getApp]->timer timer1x];
    //            snapFFWindow(FFInitialDrag[@"winDict"][@"kCGWindowOwnerName"]); //by bounds
    //            return;
    //        }
    //    }
    //    FFDragInfo = @{
    //        @"winDict": @{
    //            @"kCGWindowBounds": @{
    //                @"Width": @(curSize.width),
    //                @"Height": @(curSize.height),
    //                @"X": @(curPt.x),
    //                @"Y": @(curPt.y)
    //            },
    //            @"kCGWindowOwnerPID": @(pid),
    //            @"kCGWindowOwnerName": FFInitialDrag[@"winDict"][@"kCGWindowOwnerName"],
    //        },
    //        @"info": FFDragInfo[@"info"],
    //        @"x": @(carbonPoint.x), @"y": @(carbonPoint.y)
    //    };
    //    if (didSizeChange) {
    //        if (coordinatesChangedDuringDragCounter <= 5) { //unsnap window
    //            FFInitialDrag = FFDragInfo;
    //            unsnapFFWindow(FFInitialDrag[@"winDict"][@"kCGWindowOwnerName"]);
    //        } else { //window snapped, endFFDrag()
    //            FFDragInfo = nil;
    //            [[helperLib getApp]->timer timer1x];
    //            snapFFWindow(FFInitialDrag[@"winDict"][@"kCGWindowOwnerName"]); //by resize
    //            return;
    //        }
    //    }
    //    positionRef = (CFTypeRef) (AXValueCreate(kAXValueCGPointType, (const void *) &newPt));
        AXUIElementSetAttributeValue((AXUIElementRef)moveWindow, kAXPositionAttribute, (CFTypeRef) (AXValueCreate(kAXValueCGPointType, (const void *)&newOrigin)));
}
- (void) startMoving: (CGPoint) cursorPos : (id) tarWin : (NSRect) winFrame {
    //    if (checkingForDblClick) {
    //        // dblclick
    //        [doubleClickTimeout invalidate];
    //        checkingForDblClick = false;
    //        steviaOSGreenTrafficButton();
    //    } else {
    //        checkingForDblClick = true;
    //        doubleClickTimeout = [NSTimer scheduledTimerWithTimeInterval:DBLCLICKTIMEOUT repeats:NO block:^(NSTimer * _Nonnull timer) {
    //            checkingForDblClick = false;
    //        }];
    //    }
    //
    //    // init drag
    //    FFInitialDrag = @{
    //        @"winDict": winDict,
    //        @"info": info,
    //        @"x": @(carbonPoint.x), @"y": @(carbonPoint.y)
    //    };
    //    FFDragInfo = FFInitialDrag;
    //    [[helperLib getApp]->timer timer5x];
    //    coordinatesChangedDuringDragCounter = 0;
    NSLog(@"...starmtovnig");
    startedMoving = YES;
    startFrame = winFrame;
    moveWindow = tarWin;
}

//+ (void) updateFFSidebarShowing: (BOOL) val {
//    if (cachedWinDict) {
//        cachedWinDict = nil;
//    } else ffSidebarClosed = !val;
//}
//+ (void) trackFrontApp: (NSNotification*) notification {
//    NSRunningApplication* frontmost = [[NSWorkspace sharedWorkspace] frontmostApplication];
//    if ([[frontmost localizedName] isEqual:@"Firefox"] || [[frontmost localizedName] isEqual:@"Firefox Developer Edition"]) ffSidebarUpdateClosed([frontmost localizedName]);
//}
//- (void) timer1x {
//    [timerRef invalidate];
//    timerRef = [NSTimer scheduledTimerWithTimeInterval: TICK_DELAY target:self selector: NSSelectorFromString(@"timerTick:") userInfo: nil repeats: YES];
//    NSLog(@"timer 1x successfully started");
//}
//- (void) timer5x {
//    [timerRef invalidate];
//    timerRef = [NSTimer scheduledTimerWithTimeInterval: 0 target:self selector: NSSelectorFromString(@"timerTick:") userInfo: nil repeats: YES];
//    NSLog(@"timer 2x successfully started");
//}

- (void) defocusPIP: (Application*) app {
    id focusedWin = [helperLib elementDict: app->el : @{@"focused": (id)kAXFocusedWindowAttribute}][@"focused"];
    if (![@"Picture-in-Picture" isEqual: [helperLib elementDict: focusedWin : @{@"title": (id)kAXTitleAttribute}][@"title"]]) return;
    NSArray* visibleSpaces = Spaces.visibleSpaces;
    for (Window* win in WindowManager.windows) {
        if (win->app->pid == app->pid && [visibleSpaces containsObject: @(win->spaceId)] && ![@"Picture-in-Picture" isEqual: win->title] && !win->isMinimized) {
            AXUIElementPerformAction((AXUIElementRef)win->el, kAXRaiseAction);
            break;
        }
    }
}
@end
