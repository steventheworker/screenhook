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

    //get space index (win->title) for visible space on screen
    int spaceIndex = 0;
    NSString* screenuuid = [Spaces uuidForScreen: screen];
    NSArray* screenSpaceIds = [Spaces screenSpacesMap][screenuuid];
    NSArray* visibleSpaceIds = [Spaces visibleSpaces];
    for (NSNumber* spaceId in visibleSpaceIds) {
        if (![screenSpaceIds containsObject: spaceId]) continue;
        spaceIndex = [Spaces indexWithID: spaceId.intValue];
    }
    
    //create spacewindow
    NSWindow* spaceWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, 300, 300)
                                                        styleMask: (/*NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable */NSWindowStyleMaskBorderless)
                                                          backing: NSBackingStoreBuffered
                                                            defer: NO];
    [spaceWindow setIdentifier: @"spacewindow"];
    [spaceWindow setTitle: [NSString stringWithFormat: @"%d", spaceIndex]];
    [spaceWindow setBackgroundColor: NSColor.clearColor];
    [spaceWindow setFrame: NSMakeRect(screen.frame.origin.x, screen.frame.origin.y, 0, 0) display: YES]; //place on bottom left corner of screen
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
}
+ (BOOL) visitSpace: (int) spaceToVisit {
    NSArray* windows = [WindowManager windows];
    for (Window* win in windows) {
        if (win->app.processIdentifier == [[NSProcessInfo processInfo] processIdentifier]) { //screenhook window
            NSDictionary* dict = [helperLib elementDict: win->el : @{@"identifier": (id)kAXIdentifierAttribute, @"title": (id)kAXTitleAttribute}];
            if (![dict[@"identifier"] isEqual: @"spacewindow"] || ![[NSString stringWithFormat: @"%d", spaceToVisit] isEqual: dict[@"title"]]) continue;
            [NSApp activateIgnoringOtherApps: YES];
            AXUIElementPerformAction(win->el, kAXRaiseAction);
            setTimeout(^{[NSApp hide: nil];}, 666); // give focus back to prev. frontmost application
            return YES;
        }
    }
    return NO;
}
+ (void) keyCode: (int) keyCode {
    [Spaces updateCurrentSpace]; //now current id/index points to correct screen/space
    //find all spaces (for the screen) (in screen-space map (the one containing our current id))
    NSArray* spaces;
    NSNumber* tarSpace = @([Spaces currentSpaceId]);
    int relativeSpaceIndex = 0; //get the spaceindex (relative to the screen's spaces)
    NSDictionary* screenmap = [Spaces screenSpacesMap];
    for (NSString* uuid in screenmap) {
        NSArray* spaceIds = screenmap[uuid];
        relativeSpaceIndex = (int)[spaceIds indexOfObject: tarSpace];
        if (relativeSpaceIndex != (int)NSNotFound) {
            spaces = spaceIds;
            break;
        }
    }
    relativeSpaceIndex++; //space indexing starts from 1 (tarSpace is desktop 1 to n (relative to the screen))
    
    NSDictionary* digits = @{@18: @1, @19: @2, @20: @3, @21: @4, @23: @5, @22: @6, @26: @7, @28: @8, @25: @9};
    int digit = [digits[@(keyCode)] intValue];
    int targetSpace;
    switch (digit) { //so 1 = 0% of spaces (Space 1), 2-8 = (Space at index x/9 % of the way), 9 = 100% desktops (last Desktop)
        case 1:
            targetSpace = digit;
            break;
        case 2:
            if (spaces.count >= 2) targetSpace = digit;
            else targetSpace = 1; //there may not be a second space
            break;
        case 9:
            targetSpace = (int) spaces.count;
            break;
        default:
            targetSpace = roundf((float)digit/9 * (float)spaces.count);
            if (targetSpace <= 2) targetSpace = 3;
            break;
    }
    int targetSpaceIndex = targetSpace - 1; //array index, start at 0
    
    //the above variables are a space you want to target WITHIN the screen's spaces
    int realTargetSpaceId = [spaces[targetSpaceIndex] intValue];
    int realTargetSpaceIndex = [Spaces indexWithID: realTargetSpaceId];
    
    //if space does not yet have invisible window to activate, see if window on space exists you have axref for and activate that
        //else fallback to trigger keyboard shortcuts (control+leftarrow/rightarrow)
    if ([WindowManager exposeType] || ![self visitSpace: realTargetSpaceIndex]) //cannot go directly to space if no spacewindow created, or mission control is open
        fallbackToKeys(relativeSpaceIndex - 1, targetSpaceIndex); //currentSpaceIndex starts at 1 instead of 0
}
+ (void) spaceChanged: (NSNotification*) note {
    createSpaceWindow(NSScreen.mainScreen);
}
@end
