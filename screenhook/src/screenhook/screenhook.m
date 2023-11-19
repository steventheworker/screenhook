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

const int DEFAULT_TICK_SPEED = 333;
int intervalTickT = DEFAULT_TICK_SPEED;

@implementation screenhook
+ (void) init {
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
    
    //change space labels
    if ([eventString isEqual: @"mousedown"] && [WindowManager exposeType]) {
        CGPoint cursorPos = CGEventGetLocation(event);
        AXUIElementRef el = [helperLib elementAtPoint: cursorPos];
        int elPID = [[helperLib elementDict: el : @{@"pid": (id)kAXPIDAttribute}][@"pid"] intValue];
        if (NSRunningApplication.currentApplication.processIdentifier == elPID && cursorPos.y <= 100) { //space labels are at the top, w/o cursorPos check, interacting w/ screenhook windows in mission control is disabled!
            [missionControlSpaceLabels labelClicked: el];
            return NO;
        }
    }
    //reshow everytime, since dragging window into other space hides labels window (and can't detect moving window to another space...?)
    if ([eventString isEqual: @"mouseup"] && [WindowManager exposeType]) [missionControlSpaceLabels mouseup];
    
    //key events
    if ([eventString isEqual: @"keydown"]) {
        if ((modifiers[@"ctrl"] || modifiers[@"cmd"]) && modifiers.count == 1) {
            int keyCode = (int)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
            if ([@[@18, @19, @20, @21, @23, @22, @26, @28, @25] containsObject: @(keyCode)]) [spaceKeyboardShortcuts keyCode: keyCode];
        }
    }
    return YES;
}
+ (void) appLaunched: (NSNotification*) note {}
+ (void) appTerminated: (NSNotification*) note {}
+ (void) spaceChanged: (NSNotification*) note {
    [missionControlSpaceLabels spaceChanged: note];
    [spaceKeyboardShortcuts spaceChanged: note];
}
@end
