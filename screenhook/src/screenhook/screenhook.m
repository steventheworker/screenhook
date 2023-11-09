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

const int intervalTickT = 1000;

@implementation screenhook
+ (void) init {
    [WindowManager init];
    [missionControlSpaceLabels init];
    [self startTicking];
}
+ (void) tick {
    int exposeType = [WindowManager exposeTick]; //check exposé type, loads new shared windows (Cgwindow's)
    [missionControlSpaceLabels tick: exposeType];
}
+ (void) startTicking {
    [self tick];
    setTimeout(^{[self startTicking];}, intervalTickT); //self-perpetuate
}
+ (BOOL) processEvent: (CGEventTapProxy) proxy : (CGEventType) type : (CGEventRef) event : (void*) refcon : (NSString*) eventString {
    //change space labels
    if ([eventString isEqual: @"mousedown"] && [WindowManager exposeType]) {
        CGPoint cursorPos = CGEventGetLocation(event);
        AXUIElementRef el = [helperLib elementAtPoint: cursorPos];
        int elPID = [[helperLib elementDict: el : @{@"pid": (id)kAXPIDAttribute}][@"pid"] intValue];
        if (NSRunningApplication.currentApplication.processIdentifier == elPID) {
            [missionControlSpaceLabels labelClicked: el];
            return NO;
        }
    }
    return YES;
}
@end
