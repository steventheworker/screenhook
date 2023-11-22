//
//  screenhook.m
//  screenhook
//
//  Created by Steven G on 11/7/23.
//

#import "screenhook.h"
#import "../globals.h"
#import "../helperLib.h"
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

NSString* dockPos = @"bottom";
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
        NSLog(@"%@", cursorDict);
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
                NSArray* children = [helperLib elementDict: dockContextMenuClickee : @{@"children": (id)kAXChildrenAttribute}][@"children"];
                if (children.count) {
                    children = [helperLib elementDict: (__bridge AXUIElementRef)(children[0]) : @{@"children": (id)kAXChildrenAttribute}][@"children"];
                    if (CFEqual((__bridge AXUIElementRef)children[0], cursorEl)) dockAutohide = !dockAutohide; //the first menu item is "Turn Hiding On/Off"
                    else {
                        children = [helperLib elementDict: (__bridge AXUIElementRef)(children[2]) : @{@"children": (id)kAXChildrenAttribute}][@"children"]; //Position on screen items menu
                        children = [helperLib elementDict: (__bridge AXUIElementRef)(children[0]) : @{@"children": (id)kAXChildrenAttribute}][@"children"]; //Position on screen items menu children
                        NSLog(@"%d", children.count);
//                        if (CFEqual((__bridge AXUIElementRef)children[0], cursorEl)) dockPos = @"left";
//                        if (CFEqual((__bridge AXUIElementRef)children[1], cursorEl)) dockPos = @"bottom";
//                        if (CFEqual((__bridge AXUIElementRef)children[2], cursorEl)) dockPos = @"right";
                        for (int i = 0; i < (int)children.count; i++) {
                            AXUIElementRef el = (__bridge AXUIElementRef)(children[i]);
                            if (!CFEqual(el, cursorEl)) continue;
                            if (i == 0) {
                                
                            } else if (i == 1) {
                                
                            } else if ( i == 2) {
                                
                            }
                        }
                        NSLog(@"%@", dockPos);
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
