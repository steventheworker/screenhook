//
//  AppDelegate.m
//  screenhook
//  run applescript on:     clicks (cornerClick),  external monitor connects / disconnects (cleandesktop script "cleans"/sorts desktop icons by name)
//  Created by Steven G on 9/18/21.
//


#import "AppDelegate.h"
#import "src/helperLib.h"
#import "src/app.h"
#import "src/globals.h"
#import "src/timer.h"

NSDictionary* mouseDownCache;
//runOnce
bool waitingForTimer = NO;
void runOnceThenLater(void) {
    waitingForTimer = YES;
    [helperLib runAppleScript:@"cleandesktop"]; //todo: cleandesktop (reverse columns after, if icon1 pos.x === 0 (top left))
    setTimeout(^{waitingForTimer = NO;}, 1000); //(cleandesktop) t to runOnce --ms before trying to run the function (eg: if called 3 times in 1 seconds, still runs once)

}
void attemptRun(void) {
    if (waitingForTimer) return;
    runOnceThenLater();
}


void cornerClick(void) {
    [helperLib runAppleScript:@"cornerClick"];
    NSLog(@"cl");
}

void launchDockAltTab(void) { // DockAltTab.app file is an alias pointing to a DerivedData debug build
    NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
//    config.createsNewApplicationInstance = TRUE; // can be used to launch a new instance of vlc / blender!!!
    NSURL* aliasUrl = [NSURL fileURLWithPath: @"/Applications/MyApps/DockAltTab.app"];
    NSURLBookmarkResolutionOptions options = 0;
    options |= /* DISABLES CODE */ (1) ? NSURLBookmarkResolutionWithoutUI : 0;
    options |= /* DISABLES CODE */ (1) ? NSURLBookmarkResolutionWithoutMounting : 0;
    NSURL* _url = [NSURL URLByResolvingAliasFileAtURL: aliasUrl options: options error: nil];
    [[NSWorkspace sharedWorkspace] openApplicationAtURL:[NSURL URLWithString:  [_url absoluteString]] configuration:config completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {}];
}
void steviaOSInit(BOOL initedWithBTT) {
    launchDockAltTab();  // start DockAltTab @ login, but AFTER AltTab & BetterTouchTool (and afterBTTLaunched)
    AppDelegate* del = [helperLib getApp];
    [[del->BTTState cell] setTitle: initedWithBTT ? @"BTT initialized steviaOS ✅" : @"screenhook initialized steviaOS as a fallback ❌"];
    [del preferences: nil];
    setTimeout(^{[del closePreferences];}, 666);
    
    //toggle quickshade (turns on every login)
    if ([helperLib getPID:@"jp.questbeat.Shade"]) {
        [helperLib runScript: @"tell application \"System Events\" to tell process \"QuickShade\" to if (value of attribute \"AXMenuItemMarkChar\" of (menu item \"Enable Shade\" of menu 1 of menu bar item 1 of menu bar 2) is equal to \"✓\") then click menu bar item 1 of menu bar 2"];
        [helperLib runScript: @"tell application \"System Events\" to tell process \"QuickShade\" to if (value of attribute \"AXMenuItemMarkChar\" of (menu item \"Enable Shade\" of menu 1 of menu bar item 1 of menu bar 2) is equal to \"✓\") then perform action \"AXPress\" of (menu item \"Enable Shade\" of menu 1 of menu bar item 1 of menu bar 2)"];
    }
}

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@end
@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    void (^ __block pollForVars) (int i) = ^(int i) {
        setTimeout(^{
            if ([helperLib runScript:@"tell application \"BetterTouchTool\" to get_string_variable \"steviaOSSystemFiles\""] != nil) steviaOSInit(NO);
            else if (i < 5) pollForVars(i + 1);
            else [[self->BTTState cell] setTitle:@"restartBTT failed, steviaOSInit failed"];
            [[self->BTTState cell] setTitle: [NSString stringWithFormat:@"%@ - ran pollForVars %d times", [[self->BTTState cell] title], i]];
        }, 1000);
    };
    [app init];
    if (extScreenWidth) attemptRun(); // run cleandesktop if 2+ monitors
    
    //wait until apps launch
    setTimeout(^{
        if (self->runningApps[@"KeyCastr"]) [helperLib runScript:@"tell application \"System Events\" to tell process \"KeyCastr\" to set position of window 1 to {0, 820}"];

        if (self->runningApps[@"BTT"]) setTimeout(^{ // Ventura broke BTT Launched event (after login only)  --trigger afterBTTLaunched.scpt
            if ([helperLib runScript:@"tell application \"BetterTouchTool\" to get_string_variable \"steviaOSSystemFiles\""] == nil) {
                [helperLib runScript:@"tell application \"BetterTouchTool\" to trigger_named \"restartBTT\""];
                [[self->BTTState cell] setTitle: @"restarted... polling..."];
                pollForVars(0); // see if afterBTTLaunched ran
            } else steviaOSInit(YES);
            [helperLib runScript:@"tell application \"System Events\" to tell process \"AltTab\" to if count of windows > 0 then click button 2 of window 1"]; //close AltTab if prefs open on login, which happens when you use the login items (recommended), rather than the "Start at login" checkbox (in AltTab prefs)
        }, 6.67*1000);
        [[self->BTTState cell] setTitle: @"..."];
    }, 6.67*1000);
}
- (void) awakeFromNib {
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSSquareStatusItemLength];
    [[statusItem button] setImage: [NSImage imageNamed:@"MenuIcon"]];
    [statusItem setMenu: iconMenu];
    [statusItem setVisible: YES];
}


/*
   Event handlers
*/
- (void) mouseup: (CGEventRef) e : (CGEventType) etype {
    [timer mouseup: e : etype];
//    if (!mouseDownCache) NSLog(@"settime"); // handle mouseup ran --before mousedown finished (todo: fix this with async applescript)
    if (!mouseDownCache) return setTimeout(^{[self mouseup:e : etype];}, 84);
    
    BOOL rightBtn = (etype == kCGEventRightMouseUp);
    if (rightBtn) return;
    NSPoint pos = [NSEvent mouseLocation];
    CGPoint carbonPoint = [helperLib carbonPointFrom:pos];
    AXUIElementRef el = [helperLib elementAtPoint:carbonPoint];
    NSDictionary* info = [helperLib axInfo:el]; //axTitle, axIsApplicationRunning, axPID, axIsAPplicationRunning
    if ([info[@"role"] isEqual:@"AXDockItem"]) {
        if ([info[@"title"] isEqual:@"TaskSwitcher"]) return;
        if ([info[@"title"] isEqual:@"Spotlight Search"] && [mouseDownCache[@"info"][@"title"] isEqual:@"Spotlight Search"] && ![mouseDownCache[@"isSpotlightOpen"] intValue]) return setTimeout(^{
            if (self->runningApps[@"Alfred"]) [helperLib runScript:@"do shell script \"osascript -e 'tell application \\\"Alfred 5\\\" to search' &> /dev/null & echo $!\""];
            else [helperLib runScript:@"tell application \"System Events\" to keystroke \" \" using {command down}"];
//            NSLog(@"%@",[[[NSWorkspace sharedWorkspace] frontmostApplication] localizedName]);
        }, runningApps[@"Alfred"] ? 100 : 200); // system events is slower than app telling Alfred
    }
    
}
- (void) mousedown: (CGEventRef) e : (CGEventType) etype {
    [timer mousedown: e : etype];
    mouseDownCache = nil;
    BOOL rightBtn = (etype == kCGEventRightMouseDown);
    if (rightBtn) return;
    NSPoint pos = [NSEvent mouseLocation];
    if (primaryScreenWidth - pos.x <= 30 && primaryScreenHeight - pos.y <= 20) cornerClick();
    if (pos.x > primaryScreenWidth || pos.x < 0) { //on extended monitor
        float _extOffsetX = extOffsetX;
        if (pos.x < 0) {
            pos.x = primaryScreenWidth + (extScreenWidth + pos.x); //(external monitor to the left) --make pos as if monitor on right
            pos.y = pos.y + fabs(extOffsetY);
    //        pos.y = primaryScreenHeight + (extScreenHeight + pos.y);
            _extOffsetX = primaryScreenWidth;
        }
        if (pos.x - _extOffsetX >= extScreenWidth - 30 && pos.y >= extScreenHeight - 20) cornerClick();
    }
//    NSLog(@"%f %f", pos.x, pos.y);
    CGPoint carbonPoint = [helperLib carbonPointFrom:pos];
    AXUIElementRef el = [helperLib elementAtPoint:carbonPoint];
    NSDictionary* info = [helperLib axInfo:el]; //axTitle, axIsApplicationRunning, axPID, axIsAPplicationRunning
    mouseDownCache = @{
        @"info": info,
        @"isSpotlightOpen": @([info[@"title"] isEqual:@"Spotlight Search"] && [info[@"role"] isEqual:@"AXDockItem"] ? [app isSpotlightOpen: runningApps[@"Alfred"]] : NO)
    };
    [helperLib runAppleScript:@"screenhookClick"];
}
- (void) measureScreens { //get screen info
    NSScreen* primScreen = [helperLib getScreen:0];
    primaryScreenWidth = NSMaxX([primScreen frame]);
    primaryScreenHeight = NSMaxY([primScreen frame]);
    NSScreen* extScreen = [helperLib getScreen:1];
    extScreenWidth = [extScreen frame].size.width;
    extScreenHeight =  [extScreen frame].size.height;
    extOffsetX = [extScreen frame].origin.x;
    extOffsetY = [extScreen frame].origin.y;
    NSLog(@"screens - 1 (%f,%f) 2 (%f,%f) offset (%f,%f)", primaryScreenWidth, primaryScreenHeight, extScreenWidth, extScreenWidth, extendedOffsetX, extendedOffsetY);
}
- (void) bindScreens {
    attemptRun();
    [self measureScreens];
}


/*
    Menu Bindings / UI handlers
*/
- (IBAction) preferences:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [_window makeKeyAndOrderFront:nil];
}
- (IBAction)quit:(id)sender {[NSApp terminate:nil];}


/*
    helpers
 */
- (void) closePreferences {[_window close];}
@end
