//
//  app.m
//  screenhook
//
//  Created by Steven G on 5/9/22.
//

#import "app.h"
#import "helperLib.h"
#import "timer.h"
#import "gesture.h"
#import "autoscroll.h"

GestureManager* gm;

//config
void askForAccessibility(void) {
    NSDictionary* options = @{(__bridge NSString*)(kAXTrustedCheckOptionPrompt) : @YES};
    if (!AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options)) {
        [NSTimer scheduledTimerWithTimeInterval:3.0
        repeats:YES
        block:^(NSTimer* timer) {
            if (AXIsProcessTrusted()) { // [self relaunchIfProcessTrusted];
                [NSTask launchedTaskWithLaunchPath:[[NSBundle mainBundle] executablePath] arguments:@[]];
                [NSApp terminate:nil];
            }
        }];
    }
}

CGEventTapCallBack allHandler(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* refcon) {
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) return (CGEventTapCallBack) event;
    NSEvent* nsEvent = [NSEvent eventWithCGEvent:event];
    NSEventType eventType = [nsEvent type];
    
    if (NSEventMaskMouseMoved) { //handle mousemoved
        [autoscroll mousemoved: event : type];
    }
    
    if (eventType == NSEventTypeGesture) {
        [gm updateTouches: [nsEvent touchesMatchingPhase:NSTouchPhaseTouching inView:nil] : event : type];
        //gestures always use NSEventTypeScrollWheel (unless: if gesture set in Settings->trackpad => NSEventTypeMagnify; else if drag style is 3 finger drag => NSEventTypeLeftMouseDragged)
    } else if (eventType == NSEventTypeScrollWheel || eventType == NSEventTypeLeftMouseDragged || eventType == NSEventTypeMagnify) {
        [gm recognizeGesture: event : type];
    } else if (eventType == NSEventTypeLeftMouseDown || eventType == NSEventTypeLeftMouseUp) {
        //todo: only call, if 3 finger drag enabled (may interfere in rare case where you use external mouse and trackpad at same time???)
        if (eventType == NSEventTypeLeftMouseDown) {}  //3 finger drag triggers mousedown at the beginning/end (instead of NSEventPhaseBegan)
        else if (eventType == NSEventTypeLeftMouseUp) [gm endRecognition];  //3 finger drag triggers mouseup at the end (instead of NSEventPhaseEnded)
    } else {
        if (eventType != NSEventTypePressure && eventType != NSEventTypeSystemDefined && eventType != NSEventTypeMouseMoved && eventType != NSEventTypeLeftMouseDown && eventType != NSEventTypeLeftMouseUp && // pressure = audible click (not by tap), NSEventTypeSystemDefined = tap to click
            eventType != NSEventTypeFlagsChanged && eventType != NSEventTypeKeyUp && eventType != NSEventTypeKeyDown) { // keyboard events
            NSLog(@"%lu", (unsigned long)eventType);
        }
    }
//    if (eventType != NSEventTypeGesture && eventType != NSEventTypeMouseMoved && eventType != NSEventTypeFlagsChanged && eventType != NSEventTypeKeyUp && eventType != NSEventTypeKeyDown) NSLog(@"%lu", (unsigned long)eventType);

    return (CGEventTapCallBack) event;
}

NSString* fullDirPath(NSString* _path) {
    unichar char1 = [_path characterAtIndex:0];
    if ([[NSString stringWithCharacters:&char1 length:1] isEqual:@"~"]) {
        return [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), [_path substringFromIndex:1]];
    } else return _path;
}
@implementation app
//initialize app variables (onLaunch)
+ (void) twoFingerSwipeFromLeftEdge {
    NSRunningApplication* front = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if (!([[front localizedName] isEqual:@"Firefox"] || [[front localizedName] isEqual:@"Firefox Developer Edition"])) return;

    NSString* steviaOSSystemFiles = fullDirPath([helperLib runScript:@"tell application \"BetterTouchTool\" to get_string_variable \"steviaOSSystemFiles\""]);
    if ([steviaOSSystemFiles isEqual:@"(null)"]) return;
    NSString *path = [NSString stringWithFormat:@"%@/firefox-dev-sidebar-toggle.scpt", steviaOSSystemFiles];
    NSTask *task = [[NSTask alloc] init];
    NSString *commandToRun = [NSString stringWithFormat:@"/usr/bin/osascript -e \'run script \"%@\"'", path];
    NSLog(@"%@",commandToRun);
    NSArray *arguments = [NSArray arrayWithObjects: @"-c" , commandToRun, nil];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:arguments];
    [task launch];
}
+ (void) init {
    NSLog(@"%@", @"running app :)\n-------------------------------------------------------------------");
    // permissions
    AppDelegate* del = [helperLib getApp];
    del->_systemWideAccessibilityObject = AXUIElementCreateSystemWide();
    
    // ask for input monitoring first
    [helperLib listenMouseDown];
    [helperLib listenMouseUp];
    
    //listen gestures
    CGEventMask mask = kCGEventMaskForAllEvents;// | CGEventMaskBit();
    [helperLib listenMask:mask : (CGEventTapCallBack) allHandler];
    gm = [[GestureManager alloc] init];
    
    askForAccessibility();
    
    // permission-free events
    [del measureScreens]; // get all screen values onLaunch
    [helperLib listenScreens];

    // functional variables
    del->dockPos = [helperLib getDockPosition];
    del->runningApps = @{
        @"Alfred": @([helperLib getPID:@"com.runningwithcrayons.Alfred"]),
        @"AltTab": @([helperLib getPID:@"com.steventheworker.alt-tab-macos"]),
        @"DockAltTab": @([helperLib getPID:@"com.steventheworker.DockAltTab"]),
        @"BTT": @([helperLib getPID:@"com.hegenberg.BetterTouchTool"]),
        @"Firefox": @([helperLib getPID:@"org.mozilla.firefox"]),
//        @"Finder": @([helperLib getPID:@"com.apple.finder"]),
        @"dock": @([helperLib getPID:@"com.apple.dock"]),
        @"KeyCastr": @([helperLib getPID:@"io.github.keycastr"])
    };
    
    del->timer = [[timer alloc] init]; // start timer
    [helperLib listenRunningAppsChanged];
    
    // init UI
    if (del->runningApps[@"BTT"]) [[del->BTTState cell] setTitle:@"Checking if afterBTTLaunched..."];
    [autoscroll init];
}
+ (BOOL) isSpotlightOpen : (BOOL) isAlfred {
    return ![[helperLib runScript: [NSString stringWithFormat: @"tell application \"System Events\" to tell process \"%@\" to count of windows", isAlfred ? @"Alfred" : @"Spotlight"]] isEqual:@"0"];
}
@end

