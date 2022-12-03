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

void CoreDockSendNotification(CFStringRef, void *); // add CoreDock fn's

const int T_TO_RUN = 1; //(cleandesktop) t to runOnce --seconds before trying to run the function (eg: if called 3 times in 1 seconds, still runs once)

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@end

//runOnce
bool waitingForTimer = NO;
void runOnceThenLater(void) {
    waitingForTimer = YES;
    [helperLib runAppleScript:@"cleandesktop"]; //todo: cleandesktop (reverse columns after, if icon1 pos.x === 0 (top left))
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * T_TO_RUN), dispatch_get_main_queue(), ^() {waitingForTimer = NO;}); //setTimeout
}
void attemptRun(void) {
    if (waitingForTimer) return;
    runOnceThenLater();
}

//listen to clicks (more like mousedown's)
float primaryScreenWidth = 0;
float primaryScreenHeight = 0;
float extScreenWidth = 0;
float extScreenHeight = 0;
float extOffsetX = 0;
float extOffsetY = 0;
NSDictionary* mouseDownCache;

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
@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [app init];
    if (extScreenWidth) attemptRun(); // run cleandesktop if 2+ monitors
    setTimeout(^{if (self->runningApps[@"BTT"] && [helperLib runScript:@"tell application \"BetterTouchTool\" to get_string_variable \"steviaOSSystemFiles\""] == nil) setTimeout(^{ // Ventura broke BTT Launched event (after login only)  --trigger afterBTTLaunched.scpt
        NSString *path = [NSString stringWithFormat:@"%@/%@/afterBTTLaunched.scpt", NSHomeDirectory(), @"Desktop/important/SystemFiles"];
        NSTask *task = [[NSTask alloc] init];// BTT trigger_named  has ~ 7sec delay (on this script only)
        NSString *commandToRun = [NSString stringWithFormat:@"/usr/bin/osascript -e \'run script \"%@\"'", path];
        NSArray *arguments = [NSArray arrayWithObjects: @"-c" , commandToRun, nil];
        [task setLaunchPath:@"/bin/sh"];
        [task setArguments:arguments];
        [task launch];
        launchDockAltTab(); // start DockAltTab @ login, but AFTER AltTab & BetterTouchTool (and afterBTTLaunched)
    }, 7.5*1000);}, 7.5*1000);
}
- (void) mouseup: (CGEventRef) e : (CGEventType) etype {
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
@end
