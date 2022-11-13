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
//    [helperLib runAppleScript:@"cleandesktop"]; //todo: cleandesktop (reverse columns after, if icon1 pos.x === 0 (top left))
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

void cornerClick(void) {
    [helperLib runAppleScript:@"cornerClick"];
    NSLog(@"cl");
}
@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [app initVars];
    [helperLib listenClicks];
    [helperLib listenScreens];
    setTimeout(^{ // Ventura broke BTT Launched event (after login only)  --trigger afterBTTLaunched.scpt
        NSString *path = [NSString stringWithFormat:@"%@/%@/afterBTTLaunched.scpt", NSHomeDirectory(), @"Desktop/important/SystemFiles"];
        NSTask *task = [[NSTask alloc] init];// BTT trigger_named  has ~ 7sec delay (on this script only)
        NSString *commandToRun = [NSString stringWithFormat:@"/usr/bin/osascript -e \'run script \"%@\"'", path];
        NSArray *arguments = [NSArray arrayWithObjects: @"-c" , commandToRun, nil];
        [task setLaunchPath:@"/bin/sh"];
        [task setArguments:arguments];
        [task launch];
        // start DockAltTab @ login, but AFTER AltTab & BetterTouchTool (and afterBTTLaunched)
        [helperLib runScript:@"tell application \"DockAltTab\" to activate"];
    }, 15*1000);
}
- (void) bindClick:(CGEventRef)e :(BOOL)clickToClose {
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
    NSLog(@"%f %f", pos.x, pos.y);
    CGPoint carbonPoint = [helperLib carbonPointFrom:pos];
    AXUIElementRef elementUnderCursor = [helperLib elementAtPoint:carbonPoint];
    NSDictionary* info = [helperLib axInfo:elementUnderCursor]; //axTitle, axIsApplicationRunning, axPID, axIsAPplicationRunning
    if ([info[@"title"] isEqual:@"TaskSwitcher"] && [info[@"role"] isEqual:@"AXDockItem"]) return;
    [helperLib runAppleScript:@"screenhookClick"];
}
- (void) bindScreens { //get screen info
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
@end
