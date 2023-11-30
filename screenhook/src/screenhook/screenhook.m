//
//  screenhook.m
//  screenhook
//
//  Created by Steven G on 11/7/23.
//

#import "screenhook.h"
#import "../globals.h"
#import "../helperLib.h"
#import "../gesture.h"
#import "../prefs.h"
#import "../../AppDelegate.h"
#import "../Spaces.h"
#import "../WindowManager.h"

//features
#import "missionControlSpaceLabels.h"
#import "spaceKeyboardShortcuts.h"
#import "SpotlightSearch.h"

const int DEFAULT_TICK_SPEED = 333;
int intervalTickT = DEFAULT_TICK_SPEED;

CGPoint cursorPos; //powerpoint slide notes bug workaround (we're only allowed to grab mouse coordinates on mousedown/mouseup (or else slide note textarea focus is wacky))
AXUIElementRef cursorEl;
NSDictionary* cursorDict;
NSDictionary* mousedownDict;

int dockPos = DockBottom; //for some reason, setting a string in processEvents (when detecting click of AxMenuItem) causes dock to be blocked from accessibility... but int's work fine..........
BOOL dockAutohide = NO;
AXUIElementRef dockContextMenuClickee; //the dock separator element that was right clicked

//probably move into it's own ft. file
const float ARROWREPEAT_T = 0.66; //seconds
NSDate* lastArrowExecT;

@implementation screenhook
+ (void) init {
    lastArrowExecT = [NSDate date];
    
    cursorPos = CGPointMake(0, 0);
    dockPos = [helperLib dockPos];
    dockAutohide = [helperLib dockAutohide];
    
    [WindowManager init: ^{
        [spaceKeyboardShortcuts init];
    }];
    [missionControlSpaceLabels init];
    [self startTicking];
    
    [self startupScript];
}
+ (void) startupScript {
    //opinionated things, things that need to be added to prefs
    [GestureManager on: @"2 finger tap" : ^BOOL(GestureManager* gm) { //2 finger tap -> right click
        CGEventRef rightMouseDownEvent = CGEventCreateMouseEvent(NULL, kCGEventRightMouseDown, [helperLib CGPointFromNSPoint: [NSEvent mouseLocation]], kCGMouseButtonRight);
        CGEventPost(kCGHIDEventTap, rightMouseDownEvent);
        return YES;
    }];
    //autoscroll lock
    [GestureManager on: @"3 finger tap" : ^BOOL(GestureManager* gm) { //2 finger tap -> right click
        if ([helperLib modifierKeys].count == 3) {
            CGPoint cursorPos = [helperLib CGPointFromNSPoint: [NSEvent mouseLocation]];
            BOOL hasWindows = NO;
            for (Window* win in WindowManager.windows) if ([win->app->name isEqual: @"AutoScroll"]) hasWindows = YES;
            if (!hasWindows) {
                CGEventRef middleClick = CGEventCreateMouseEvent(NULL, kCGEventOtherMouseDown, cursorPos, kCGMouseButtonCenter);
                CGEventPost(kCGHIDEventTap, middleClick);
            } else {
                CGEventRef middleClickRelease = CGEventCreateMouseEvent(NULL, kCGEventOtherMouseUp, cursorPos, kCGMouseButtonCenter);
                CGEventPost(kCGHIDEventTap, middleClickRelease);
            }
        }
        return YES;
    }];
    
    [GestureManager on: @"3 finger swipe left" : ^BOOL(GestureManager* gm) {[spaceKeyboardShortcuts nextSpace];return YES;}];
    [GestureManager on: @"3 finger swipe right" : ^BOOL(GestureManager* gm) {[spaceKeyboardShortcuts prevSpace];return YES;}];
    [GestureManager on: @"4 finger swipe left" : ^BOOL(GestureManager* gm) {[spaceKeyboardShortcuts nextSpace];return YES;}];
    [GestureManager on: @"4 finger swipe right" : ^BOOL(GestureManager* gm) {[spaceKeyboardShortcuts prevSpace];return YES;}];
    [GestureManager on: @"3 finger swipe down" : ^BOOL(GestureManager* gm) {[helperLib openAppExpose];return YES;}];
    [GestureManager on: @"3 finger swipe up" : ^BOOL(GestureManager* gm) {[helperLib openMissionControl];return YES;}];
}
+ (void) tick {
    int exposeType = [WindowManager exposeTick]; //check exposé type, loads new shared windows (Cgwindow's)
    if (!exposeType) intervalTickT = DEFAULT_TICK_SPEED; else intervalTickT = DEFAULT_TICK_SPEED / 3;
    [missionControlSpaceLabels tick: exposeType];
}
+ (void) startTicking {
    [self tick];
    setTimeout(^{[self startTicking];}, intervalTickT); //self-perpetuate
}
+ (BOOL) processEvent: (CGEventTapProxy) proxy : (CGEventType) type : (CGEventRef) event : (void*) refcon : (NSString*) eventString {
    NSDictionary* modifiers = [helperLib modifierKeys];
    /*
        mouse events
     */
    if ([eventString isEqual: @"mousedown"] || [eventString isEqual: @"mouseup"]) { //core mousedown/mouseup
        cursorPos = CGEventGetLocation(event);
        cursorEl = [helperLib elementAtPoint: [helperLib normalizePointForDockGap: cursorPos : dockPos]];
        cursorDict = [helperLib elementDict: cursorEl : @{
            @"pid": (id)kAXPIDAttribute,
            @"title": (id)kAXTitleAttribute,
            @"identifier": (id)kAXIdentifierAttribute,
            @"subrole": (id)kAXSubroleAttribute,
            @"role": (id)kAXRoleAttribute
        }];
        BOOL dockClick = [cursorDict[@"pid"] intValue] == [WindowManager appWithBID: @"com.apple.dock"]->pid;
        setTimeout(^{mousedownDict = cursorDict;}, 0);
        
        //live onchange of dock settings (dockPos, dockautohide)
        if (dockClick) {
            if ([cursorDict[@"subrole"] isEqual: @"AXSeparatorDockItem"] &&
                (type == kCGEventRightMouseDown || (type == kCGEventOtherMouseUp && [mousedownDict[@"subrole"] isEqual: @"AXSeparatorDockItem"]))
            ) { //cache the element so if a context menu item is selected we'll compare & know when a dock setting changes
                dockContextMenuClickee = cursorEl;
            }
        }
        if ([cursorDict[@"role"] isEqual: @"AXMenuItem"]) { //context menu item is being selected/triggered
            if (dockContextMenuClickee && type == kCGEventLeftMouseUp) {
                __block NSArray* children = [helperLib elementDict: dockContextMenuClickee : @{@"children": (id)kAXChildrenAttribute}][@"children"];
                if (children.count) { //there is a menu!
                    children = [helperLib elementDict: (__bridge AXUIElementRef)(children[0]) : @{@"children": (id)kAXChildrenAttribute}][@"children"]; //menu items
                    if (CFEqual((__bridge AXUIElementRef)children[0], cursorEl)) dockAutohide = !dockAutohide; //the first menu item is "Turn Hiding On/Off"
                    else {
                        children = [helperLib elementDict: (__bridge AXUIElementRef)(children[2]) : @{@"children": (id)kAXChildrenAttribute}][@"children"]; //Position on screen items menu
                        children = [helperLib elementDict: (__bridge AXUIElementRef)(children[0]) : @{@"children": (id)kAXChildrenAttribute}][@"children"]; //Position on screen items menu children
                        if (CFEqual((__bridge AXUIElementRef)children[0], cursorEl)) dockPos = DockLeft;
                        if (CFEqual((__bridge AXUIElementRef)children[1], cursorEl)) dockPos = DockBottom;
                        if (CFEqual((__bridge AXUIElementRef)children[2], cursorEl)) dockPos = DockRight;
                    }
                }
            }
        }
        /* end core mousedown/mouseup */
    }
    //change space labels
    if ([eventString isEqual: @"mousedown"] && [WindowManager exposeType]) return [missionControlSpaceLabels mousedown: cursorEl : cursorDict : cursorPos];
    if ([eventString isEqual: @"mouseup"] && [WindowManager exposeType]) [missionControlSpaceLabels mouseup]; //reshow everytime, since dragging window into other space hides labels window (and can't detect moving window to another space...?)
    
    //spotlight search
    if ([eventString isEqual: @"mousedown"] && [cursorDict[@"title"] isEqual: @"Spotlight Search"]) return [SpotlightSearch mousedown: cursorPos : cursorEl : cursorDict];
    if ([eventString isEqual: @"mouseup"]) return [SpotlightSearch mouseup: cursorPos : cursorEl : cursorDict];

    /*
        key events
     */
    if ([eventString isEqual: @"keydown"] || [eventString isEqual: @"keyup"]) {
        int keyCode = (int)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
        
        //spaceKeyboardShortcuts
        if ([eventString isEqual: @"keydown"] && (modifiers[@"ctrl"] || modifiers[@"cmd"]) && modifiers.count == 1)
            if ([@[@18, @19, @20, @21, @23, @22, @26, @28, @25] containsObject: @(keyCode)]) [spaceKeyboardShortcuts keyCode: keyCode];

        //ctrl+left-arrow
        if ([eventString isEqual: @"keydown"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 123) {
            NSDate* t0 = lastArrowExecT;
            lastArrowExecT = NSDate.date;
            if ([lastArrowExecT timeIntervalSinceDate: t0] <= ARROWREPEAT_T) return YES;
            [spaceKeyboardShortcuts prevSpace];
            return NO;
        }
        if ([eventString isEqual: @"keyup"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 123) {
            NSDate* t0 = lastArrowExecT;
            lastArrowExecT = NSDate.date;
            if ([lastArrowExecT timeIntervalSinceDate: t0] <= ARROWREPEAT_T) return YES;
            return NO;
        }
        //ctrl+right-arrow
        if ([eventString isEqual: @"keydown"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 124) {
            NSDate* t0 = lastArrowExecT;
            lastArrowExecT = NSDate.date;
            if ([lastArrowExecT timeIntervalSinceDate: t0] <= ARROWREPEAT_T) return YES;
            [spaceKeyboardShortcuts nextSpace];
            return NO;
        }
        if ([eventString isEqual: @"keyup"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 124) {
            NSDate* t0 = lastArrowExecT;
            lastArrowExecT = NSDate.date;
            if ([lastArrowExecT timeIntervalSinceDate: t0] <= ARROWREPEAT_T) return YES;
            return NO;
        }
    }
    return YES;
}
+ (void) appLaunched: (NSRunningApplication*) runningApp {
    NSLog(@"launched '%@' - %@", runningApp, runningApp.bundleIdentifier);
}
+ (void) appTerminated: (NSRunningApplication*) runningApp {
    NSLog(@"terminated '%@' - %@", runningApp, runningApp.bundleIdentifier);
}
+ (void) spaceChanged: (NSNotification*) note {
    [missionControlSpaceLabels spaceChanged: note];
    [spaceKeyboardShortcuts spaceChanged: note];
}
+ (void) spaceadded: (int) spaceIndex { // event from missionControlSpaceLabels
    [spaceKeyboardShortcuts spaceadded: spaceIndex]; //update spacewindow's
}
+ (void) spaceremoved: (int) spaceIndex { // event from missionControlSpaceLabels
    [spaceKeyboardShortcuts spaceremoved: spaceIndex]; //update spacewindow's
}
+ (void) spacemoved: (int) monitorStartIndex : (NSArray*) newIndexing { // event from missionControlSpaceLabels
    [spaceKeyboardShortcuts spacemoved: monitorStartIndex : newIndexing]; //update spacewindow's
}
+ (void) processScreens: (CGDirectDisplayID) display : (CGDisplayChangeSummaryFlags) flags : (void*) userInfo {
    //    kCGDisplayBeginConfigurationFlag      = (1 << 0),
    //    kCGDisplayMovedFlag                   = (1 << 1),
    //    kCGDisplaySetMainFlag                 = (1 << 2),
    //    kCGDisplaySetModeFlag                 = (1 << 3),
    //    kCGDisplayAddFlag                     = (1 << 4),
    //    kCGDisplayRemoveFlag                  = (1 << 5),
    //    kCGDisplayEnabledFlag                 = (1 << 8),
    //    kCGDisplayDisabledFlag                = (1 << 9),
    //    kCGDisplayMirrorFlag                  = (1 << 10),
    //    kCGDisplayUnMirrorFlag                = (1 << 11),
    //    kCGDisplayDesktopShapeChangedFlag     = (1 << 12)
    NSScreen* screen = [Spaces screenWithDisplayID: display];
    NSString* uuid;
    if (flags & kCGDisplayRemoveFlag) { //get uuid by elimination w/ cached screenMap (since
        NSDictionary* screenSpacesMap = [Spaces screenSpacesMap]; //cache of the old screenSpacesMap
        NSMutableArray* mapUUIDs = [NSMutableArray arrayWithArray: screenSpacesMap.allKeys];
        for (NSScreen* scr in NSScreen.screens) [mapUUIDs removeObject: [Spaces uuidForScreen: scr]]; //filter out uuid's that still exist
        uuid = mapUUIDs.firstObject; //should be the only object left
    } else uuid = [Spaces uuidForScreen: screen];
    
    [missionControlSpaceLabels processScreens: screen : flags : uuid]; //update spacelabel's
    [spaceKeyboardShortcuts processScreens: screen : flags : uuid]; //update spacewindow's
    
    if ((flags & kCGDisplayAddFlag) || (flags & kCGDisplayRemoveFlag)) { //now, update screenMap
        [Spaces refreshAllIdsAndIndexes];
        [Spaces updateCurrentSpace];
    }
}
@end
