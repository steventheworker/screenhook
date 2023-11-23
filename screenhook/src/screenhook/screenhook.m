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

@implementation screenhook
+ (void) init {
    cursorPos = CGPointMake(0, 0);
    dockPos = [helperLib dockPos];
    dockAutohide = [helperLib dockAutohide];
    
    [WindowManager init];
    [missionControlSpaceLabels init];
    [spaceKeyboardShortcuts init];
    [self startTicking];
    
    [self startupScript];
}
+ (void) startupScript {
    [GestureManager on: @"2 finger tap" : ^BOOL(GestureManager* gm) {
        CGEventRef rightMouseDownEvent = CGEventCreateMouseEvent(
            NULL,
            kCGEventRightMouseDown,
            [helperLib CGPointFromNSPoint: [NSEvent mouseLocation]],
            kCGMouseButtonRight
        );
        CGEventPost(kCGHIDEventTap, rightMouseDownEvent);
        return YES;
    }];
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
    if ([eventString isEqual: @"mousedown"] || [eventString isEqual: @"mouseup"]) { //core block
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
    }
    //change space labels
    if ([eventString isEqual: @"mousedown"] && [WindowManager exposeType]) {
        if (NSRunningApplication.currentApplication.processIdentifier == [cursorDict[@"pid"] intValue] && cursorPos.y <= 100) { //space labels are at the top, w/o cursorPos check, interacting w/ screenhook windows in mission control is disabled!
            [missionControlSpaceLabels labelClicked: cursorEl];
            return NO;
        }
    }
    if ([eventString isEqual: @"mouseup"] && [WindowManager exposeType]) [missionControlSpaceLabels mouseup]; //reshow everytime, since dragging window into other space hides labels window (and can't detect moving window to another space...?)
    
    //spotlight search
    if ([eventString isEqual: @"mousedown"] && [cursorDict[@"title"] isEqual: @"Spotlight Search"]) return [SpotlightSearch mousedown: cursorPos : cursorEl : cursorDict];
    if ([eventString isEqual: @"mouseup"]) return [SpotlightSearch mouseup: cursorPos : cursorEl : cursorDict];

    /*
        key events
     */
    //spaceKeyboardShortcuts
    if ([eventString isEqual: @"keydown"]) {
        if ((modifiers[@"ctrl"] || modifiers[@"cmd"]) && modifiers.count == 1) {
            int keyCode = (int)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
            if ([@[@18, @19, @20, @21, @23, @22, @26, @28, @25] containsObject: @(keyCode)]) [spaceKeyboardShortcuts keyCode: keyCode];
        }
    }
    
    return YES;
}
+ (void) appLaunched: (NSNotification*) note {
    NSRunningApplication* app = (NSRunningApplication*)note.userInfo[@"NSWorkspaceApplicationKey"];
    NSLog(@"launched '%@' - %@", app, app.bundleIdentifier);
}
+ (void) appTerminated: (NSNotification*) note {
    NSRunningApplication* app = (NSRunningApplication*)note.userInfo[@"NSWorkspaceApplicationKey"];
    NSLog(@"terminated '%@' - %@", app, app.bundleIdentifier);
}
+ (void) spaceChanged: (NSNotification*) note {
    [missionControlSpaceLabels spaceChanged: note];
    [spaceKeyboardShortcuts spaceChanged: note];
}
@end
