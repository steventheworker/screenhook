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

NSWindow* createSpaceWindow(int spaceIndex, NSScreen* screen) {
    for (NSWindow* win in NSApp.windows) if ([win.identifier isEqual: @"spacewindow"] && win.title.intValue == spaceIndex) {
        NSLog(@"spacewindow w/ index %d already exists", spaceIndex);
        return nil;
    }
    NSWindow* spaceWindow = [[NSWindow alloc] initWithContentRect: NSMakeRect(0, 0, /* 300 */ 0, /* 300 */ 0)
                                                        styleMask: (/*NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable */NSWindowStyleMaskBorderless)
                                                          backing: NSBackingStoreBuffered
                                                            defer: NO
                                                           screen: screen ? screen : [helperLib screenWithMouse]];
    [spaceWindow setIdentifier: @"spacewindow"];
    [spaceWindow setTitle: [NSString stringWithFormat: @"%d", spaceIndex]];
    [spaceWindow setBackgroundColor: NSColor.clearColor];
    [spaceWindow setIgnoresMouseEvents: YES]; //pass clicks through (which it already does so, when using nscolor.clearcolor (For some reason))
    [spaceWindow makeKeyAndOrderFront: nil]; //pop it up
//    [spaceWindow setFrame: NSMakeRect(screen.frame.origin.x, screen.frame.origin.y, 0, 0) display: YES]; //place on bottom left corner of screen
    CFBridgingRetain(spaceWindow);
    return spaceWindow;
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
    //add a spacewindow titled spaceIndex into all spaces!
    NSDictionary* screenSpacesMap = Spaces.screenSpacesMap;
    for (NSString* UUID in screenSpacesMap) {
        NSScreen* screen;for (screen in NSScreen.screens) if ([[Spaces uuidForScreen: screen] isEqual: UUID]) break;
        NSArray* screenSpaces = screenSpacesMap[UUID];
        for (NSNumber* spaceId in screenSpaces) {
            int spaceIndex = [Spaces indexWithID: spaceId.intValue];
            NSWindow* win = createSpaceWindow(spaceIndex, screen);
            CGSMoveWindowsToManagedSpace(Spaces.CGSMainConnectID, (__bridge CFArrayRef)(@[@(win.windowNumber)]), spaceId.intValue);
        }
    }
}
+ (BOOL) visitSpace: (int) spaceIndex {
    NSArray* windows = [WindowManager windows];
    for (Window* win in windows) {
        if (win->app->pid == [[NSProcessInfo processInfo] processIdentifier]) { //screenhook window
            NSDictionary* dict = [helperLib elementDict: win->el : @{@"identifier": (id)kAXIdentifierAttribute, @"title": (id)kAXTitleAttribute}];
            if (![dict[@"identifier"] isEqual: @"spacewindow"] || ![[NSString stringWithFormat: @"%d", spaceIndex] isEqual: dict[@"title"]]) continue;
            [NSApp activateIgnoringOtherApps: YES];
            AXUIElementPerformAction((AXUIElementRef)win->el, kAXRaiseAction);
            setTimeout(^{[NSApp hide: nil];}, 666); // give focus back to prev. frontmost application
            return YES;
        }
    }
    return NO;
}
+ (void) prevSpace { //prev space on monitor under mouse
    [Spaces updateCurrentSpace]; //now current id/index points to correct screen/space
    CGPoint mouseLoc = [helperLib CGPointFromNSPoint: [NSEvent mouseLocation]];
    NSScreen* mouseScreen = [helperLib screenAtCGPoint: mouseLoc];
    NSArray* visibleSpaces = [Spaces visibleSpaces];
    NSMutableArray* visibleIndexes = [NSMutableArray array];
    for (NSNumber* spaceId in visibleSpaces) [visibleIndexes addObject: @([Spaces indexWithID: spaceId.intValue])];
    NSWindow* win;for (win in NSApp.windows) {
        if (![win.identifier isEqual: @"spacewindow"] || ![visibleIndexes containsObject: @(win.title.intValue)]) continue;
        NSScreen* winScreen = [helperLib screenAtCGPoint: CGPointMake(win.frame.origin.x, win.frame.origin.y)];
        if (winScreen == mouseScreen) break; //found space win
    }
    int spaceIndex = win.title.intValue;
    NSArray* screenSpaceIds = [Spaces screenSpacesMap][[Spaces uuidForScreen: mouseScreen]];
    int relativeIndex = (int)[screenSpaceIds indexOfObject: visibleSpaces[ [visibleIndexes indexOfObject: @(spaceIndex)] ]];
    if (relativeIndex - 1 < 0) spaceIndex += screenSpaceIds.count;
    if ([WindowManager exposeType] || ![self visitSpace: spaceIndex - 1]) //cannot go directly to space if no spacewindow created, or mission control is open
        fallbackToKeys(relativeIndex, relativeIndex - 1);
}
+ (void) nextSpace { //next space on monitor under mouse
    [Spaces updateCurrentSpace]; //now current id/index points to correct screen/space
    CGPoint mouseLoc = [helperLib CGPointFromNSPoint: [NSEvent mouseLocation]];
    NSScreen* mouseScreen = [helperLib screenAtCGPoint: mouseLoc];
    NSArray* visibleSpaces = [Spaces visibleSpaces];
    NSMutableArray* visibleIndexes = [NSMutableArray array];
    for (NSNumber* spaceId in visibleSpaces) [visibleIndexes addObject: @([Spaces indexWithID: spaceId.intValue])];
    NSWindow* win;for (win in NSApp.windows) {
        if (![win.identifier isEqual: @"spacewindow"] || ![visibleIndexes containsObject: @(win.title.intValue)]) continue;
        NSScreen* winScreen = [helperLib screenAtCGPoint: CGPointMake(win.frame.origin.x, win.frame.origin.y)];
        if (winScreen == mouseScreen) break; //found space win
    }
    int spaceIndex = win.title.intValue;
    NSArray* screenSpaceIds = [Spaces screenSpacesMap][[Spaces uuidForScreen: mouseScreen]];
    int relativeIndex = (int)[screenSpaceIds indexOfObject: visibleSpaces[ [visibleIndexes indexOfObject: @(spaceIndex)] ]];
    if (relativeIndex + 1 > screenSpaceIds.count - 1) spaceIndex -= screenSpaceIds.count;
    if ([WindowManager exposeType] || ![self visitSpace: spaceIndex + 1]) //cannot go directly to space if no spacewindow created, or mission control is open
        fallbackToKeys(relativeIndex, relativeIndex + 1);
}
+ (void) keyCode: (int) keyCode {
    [Spaces updateCurrentSpace]; //now current id/index points to correct screen/space
    //find all spaces (for the screen) (in screen-space map (the one containing our current id))
    NSArray* spaces;
    NSNumber* tarSpace = @(Spaces.currentSpaceId);
    int relativeSpaceIndex = 0; //get the spaceindex (relative to the screen's spaces)
    NSDictionary* screenmap = Spaces.screenSpacesMap;
    for (NSString* uuid in screenmap) {
        NSArray* spaceIds = screenmap[uuid];
        relativeSpaceIndex = (int)[spaceIds indexOfObject: tarSpace];
        if (relativeSpaceIndex != (int)NSNotFound) {
            spaces = spaceIds;
            break;
        }
    }
    relativeSpaceIndex += 1; //space indexing starts from 1 (tarSpace is desktop 1 to n (relative to the screen))
    
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
    int spaceIndex = 0; //get space index (win->title) for screen that changed space's new visible space
    NSString* screenuuid = [Spaces uuidForScreen: NSScreen.mainScreen];
    NSArray* screenSpaceIds = [Spaces screenSpacesMap][screenuuid];
    NSArray* visibleSpaceIds = [Spaces visibleSpaces];
    for (NSNumber* spaceId in visibleSpaceIds) {
        if (![screenSpaceIds containsObject: spaceId]) continue;
        spaceIndex = [Spaces indexWithID: spaceId.intValue];
    }
    createSpaceWindow(spaceIndex, NSScreen.mainScreen);
}
+ (void) spaceadded: (int) spaceIndex { // event from missionControlSpaceLabels
    for (NSWindow* win in NSApp.windows) {
        if (![win.identifier isEqual: @"spacewindow"]) continue;
        //increment all spacewindow titles >= spaceIndex
        if (win.title.intValue >= spaceIndex) [win setTitle: [NSString stringWithFormat: @"%d", win.title.intValue + 1]];
    }
    //create a spacewindow titled spaceIndex
    NSWindow* win = createSpaceWindow(spaceIndex, nil);
    //move it to the spaceIndex (since creating a space still leaves you in the currentSpace)
    CGSMoveWindowsToManagedSpace([Spaces CGSMainConnectID], (__bridge CFArrayRef)(@[@(win.windowNumber)]), [Spaces IDWithIndex: spaceIndex]);
}
+ (void) spaceremoved: (int) spaceIndex { // event from missionControlSpaceLabels
    //delete spacewindow titled spaceIndex
    for (NSWindow* win in NSApp.windows)
        if ([win.identifier isEqual: @"spacewindow"])
        if (win.title.intValue == spaceIndex)
            [win close];
    //decrement all spacewindow titles > spaceIndex
    for (NSWindow* win in NSApp.windows)
        if ([win.identifier isEqual: @"spacewindow"])
        if (win.title.intValue > spaceIndex)
            [win setTitle: [NSString stringWithFormat: @"%d", win.title.intValue - 1]];
}
+ (void) spacemoved: (int) monitorStartIndex : (NSArray*) newIndexing { // event from missionControlSpaceLabels
    NSMutableArray<NSWindow*>* wins = [NSMutableArray array];
    for (int i = 0; i < newIndexing.count; i++)
        for (NSWindow* win in NSApp.windows) if (win.title.intValue == i + monitorStartIndex) [wins addObject: win];
    NSMutableArray* winTitles = [NSMutableArray array];
    for (int i = 0; i < wins.count; i++)
        [winTitles addObject: wins[i].title];
    for (int i = 0; i < newIndexing.count; i++)
        [wins[i] setTitle: winTitles[[newIndexing[i] intValue]]];
}
+ (void) processScreens: (NSScreen*) screen : (CGDisplayChangeSummaryFlags) flags : (NSString*) uuid {
    if (flags & kCGDisplayAddFlag) {
        NSDictionary* screenSpacesMap1 = [Spaces screenSpacesMap];
        NSString* primaryUUID = [Spaces uuidForScreen: [Spaces cachedPrimaryScreen]];
        NSArray* primaryScreenSpaces1 = screenSpacesMap1[primaryUUID];
        setTimeout(^{//wait for screenSpacesMap to update
            NSDictionary* screenSpacesMap2 = [Spaces screenSpacesMap];
            NSArray* screenSpaces = screenSpacesMap2[uuid]; //every space after the 1st on the added screen came from the primary screen (the 1st was just created)
            NSArray* primaryScreenSpaces2 = screenSpacesMap2[primaryUUID];
            int newScreenStartIndex = [screenSpaces.firstObject intValue];
            int numSpacesMoved = (int)screenSpaces.count - 1; // 1st space wasn't moved (was creasted)
            int movedStartIndex = 0;
            for (NSNumber* spaceId in primaryScreenSpaces1) {
                movedStartIndex++;
                if (![primaryScreenSpaces2 containsObject: spaceId]) break;
            }
            for (NSWindow* win in NSApp.windows) { //update moved spacewindow spaceIndex's/title's
                if (![win.identifier isEqual: @"spacewindow"]) continue;
                if (win.title.intValue >= movedStartIndex && win.title.intValue < movedStartIndex + numSpacesMoved) {
                    int newSpaceIndex = newScreenStartIndex + ((win.title.intValue - movedStartIndex) + 1);
                    [win setTitle: [NSString stringWithFormat: @"%d", newSpaceIndex]];
                }
            }
            createSpaceWindow([Spaces indexWithID: newScreenStartIndex], screen);
        }, 0);
    } else if (flags & kCGDisplayRemoveFlag) {
        NSDictionary* screenSpacesMap = [Spaces screenSpacesMap];
        NSArray* primaryScreenSpaces = screenSpacesMap[[Spaces uuidForScreen: [Spaces cachedPrimaryScreen]]];
        NSArray* screenSpaces = screenSpacesMap[uuid];
        int firstSpaceIndex = [Spaces indexWithID: [screenSpaces.firstObject intValue]]; //the first spaceIndex of the removed screen no longer exists (merged into primary monitor's space 1)
        int primaryMonitorLastIndex = [Spaces indexWithID: [primaryScreenSpaces.lastObject intValue]];
        for (NSWindow* win in NSApp.windows) {
            if (![win.identifier isEqual: @"spacewindow"]) continue;
            if (win.title.intValue == firstSpaceIndex) [win close]; //remove first spaceIndex of remoed screen
            if (win.title.intValue > firstSpaceIndex && win.title.intValue < firstSpaceIndex + screenSpaces.count) { //update the rest of the spaces from removed screen's spaceIndex's
                int newSpaceIndex = primaryMonitorLastIndex + (win.title.intValue - firstSpaceIndex);
                [win setTitle: [NSString stringWithFormat: @"%d", newSpaceIndex]];
            }
        }
    }
}
@end
