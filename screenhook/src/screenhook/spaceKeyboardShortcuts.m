//
//  spaceKeyboardShortcuts.m
//  screenhook
//
//  Created by Steven G on 11/10/23.
//

#import "spaceKeyboardShortcuts.h"
#import "../globals.h"
#import "../helperLib.h"
#import "../Spaces.h"
#import "../WindowManager.h"

extern void CGSManagedDisplaySetCurrentSpace(const /* CGSConnectionID */ int cid, /* CGSManagedDisplay */ CFStringRef display, /* CGSSpace */ uint64_t space);
extern /* CGSManagedDisplay */ CFStringRef kCGSPackagesMainDisplayIdentifier;

void createSpaceWindow(NSScreen* screen) {
    //put invisible window on space (if DNE)
    AXUIElementRef appEl = AXUIElementCreateApplication([[NSRunningApplication currentApplication] processIdentifier]);
    NSArray* windows = [helperLib elementDict: appEl : @{@"wins": (id)kAXWindowsAttribute}][@"wins"];
    for (NSValue* elval in windows) {
        AXUIElementRef el = elval.pointerValue;
        NSDictionary* dict = [helperLib elementDict: el : @{@"id": (id)kAXIdentifierAttribute, @"pos": (id)kAXPositionAttribute}];
        NSPoint pos = NSMakePoint([dict[@"pos"][@"x"] floatValue], [dict[@"pos"][@"y"] floatValue]);
        if ([@"spacewindow" isEqual: dict[@"id"]] && NSPointInRect(pos, screen.frame)) return; // already exists on screen
    }
    //create spacewindow
    NSWindow* spaceWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 300, 300)
                                                        styleMask: (/*NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable */NSWindowStyleMaskBorderless)
                                                          backing: NSBackingStoreBuffered
                                                            defer: NO];
    [spaceWindow setIdentifier: @"spacewindow"];
    [spaceWindow setLevel: NSMainMenuWindowLevel]; //prevent show up in mission control (but floats on top)
    [spaceWindow setBackgroundColor: /*NSColor.redColor*/ NSColor.clearColor];
    [spaceWindow setFrame: NSMakeRect(screen.frame.origin.x, screen.frame.origin.y, 300, 300) display: YES]; //place on bottom left corner of screen
    [spaceWindow setIgnoresMouseEvents: YES]; //pass clicks through (which it already does so, when using nscolor.clearcolor (For some reason))
    [spaceWindow makeKeyAndOrderFront: nil]; //pop it up
}

void fallbackToKeys(int from, int to) {
    int dx = to - from;
    for (int i = 0; i < abs(dx); i++) {
        NSString* scptStr = [NSString stringWithFormat: @"tell application \"System Events\" to key code %d using {control down}", dx < 0 ? 123 : 124];
        setTimeout(^{
            [helperLib applescript: scptStr];
        }, ([WindowManager exposeType] ? 750 : 100) * i + 333);
    }
}

@implementation spaceKeyboardShortcuts
+ (void) init {
    for (NSScreen* screen in NSScreen.screens) createSpaceWindow(screen);


    AXUIElementRef appEl = AXUIElementCreateApplication([[NSRunningApplication currentApplication] processIdentifier]);
    NSArray* windows = [helperLib elementDict: appEl : @{@"wins": (id)kAXWindowsAttribute}][@"wins"];
    AXUIElementRef el;
    for (NSValue* elval in windows) {
        el = elval.pointerValue;
        NSDictionary* dict = [helperLib elementDict: el : @{@"id": (id)kAXIdentifierAttribute, @"pos": (id)kAXPositionAttribute}];
        NSPoint pos = NSMakePoint([dict[@"pos"][@"x"] floatValue], [dict[@"pos"][@"y"] floatValue]);
        if ([@"spacewindow" isEqual: dict[@"id"]] && NSPointInRect(pos, NSScreen.mainScreen.frame)) break;
    }
}
+ (void) keyCode: (int) keyCode {
    NSArray* spaces = [Spaces spaces];
    NSDictionary* digits = @{@18: @1, @19: @2, @20: @3, @21: @4, @23: @5, @22: @6, @26: @7, @28: @8, @25: @9};
    int digit = [digits[@(keyCode)] intValue];
    int targetSpace;
    switch (digit) { //so 1 = 0% of spaces (Space 1), 2-8 = (Space at index x/9 % of the way), 9 = 100% desktops (last Desktop)
        case 1:
        case 2:
            targetSpace = digit;
            break;
        case 9:
            targetSpace = (int) spaces.count;
            break;
        default:
            targetSpace = roundf((float)digit/9 * (float)spaces.count);
            break;
    }
    int targetSpaceIndex = targetSpace - 1;
    
    //if space does not yet have invisible window to activate, see if window on space exists you have axref for and activate that
        //else fallback to trigger keyboard shortcuts (control+leftarrow/rightarrow)
    fallbackToKeys([Spaces currentSpaceIndex] - 1, targetSpaceIndex); //currentSpaceIndex starts at 1 instead of 0
}
+ (void) spaceChanged: (NSNotification*) note {
    createSpaceWindow(NSScreen.mainScreen);
}
@end
