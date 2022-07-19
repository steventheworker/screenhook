//
//  AppDelegate.m
//  screenhook
//  run applescript on:     clicks (cornerClick),  external monitor connects / disconnects (cleandesktop script "cleans"/sorts desktop icons by name)
//  Created by Steven G on 9/18/21.
//


#import "exposelib.h"

#import "AppDelegate.h"
#include <ApplicationServices/ApplicationServices.h>
CG_EXTERN void CoreDockSendNotification(CFStringRef, void *); // add CoreDock fn's

const int T_TO_RUN = 1; //(cleandesktop) t to runOnce --seconds before trying to run the function (eg: if called 3 times in 1 seconds, still runs once)

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@end

//applescript & runOnce
void runApplescript(NSString* scriptName) {
    NSString *compiledScriptPath = [[NSBundle mainBundle] pathForResource:scriptName ofType:@"scpt" inDirectory:@"Scripts"];
    NSDictionary *error = nil;
    NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:compiledScriptPath] error:&error];
    if (error) {
        NSLog(@"compile error: %@", error);
    } else {
       [script executeAndReturnError:&error];
       if (error) {
         NSLog(@"run error: %@", error);
       }
    }
}
bool waitingForTimer = NO;
void runOnceThenLater(void) {
    waitingForTimer = YES;
    runApplescript(@"cleandesktop");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * T_TO_RUN), dispatch_get_main_queue(), ^() {waitingForTimer = NO;}); //setTimeout
}
void attemptRun(void) {
    if (waitingForTimer) return;
    runOnceThenLater();
}

//for some reason the "add" & "remove" Hook's don't ever get called (due to flags (always both (is suspicious to me (hmmm))))
void addHook(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void* userInfo) {NSLog(@"%@", @"add screen");attemptRun();}
void removeHook(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void* userInfo) {NSLog(@"%@", @"remove screen");attemptRun();}
void hook(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void* userInfo) {NSLog(@"%@", @"add&remove screen");attemptRun();}
void proc(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags, void* userInfo) {
    if (flags && kCGDisplayAddFlag && kCGDisplayRemoveFlag) hook(display, flags, userInfo);
    else if (flags && kCGDisplayAddFlag) addHook(display, flags, userInfo);
    else if (flags && kCGDisplayRemoveFlag) removeHook(display, flags, userInfo);
    else NSLog(@"unknown flag O_O");
    [AppDelegate bindScreens];
}

//listen to clicks (more like mousedown's)
float primaryScreenWidth = 0;
float primaryScreenHeight = 0;
float extScreenWidth = 0;
float extScreenHeight = 0;
float extOffsetX = 0;
float extOffsetY = 0;

void cornerClick(void) {
//
    runApplescript(@"cornerClick");
}
void handleClick(void) {
    NSPoint pos = [NSEvent mouseLocation];
    if (primaryScreenWidth - pos.x <= 30 && primaryScreenHeight - pos.y <= 20) cornerClick();
    if (pos.x > primaryScreenWidth) { //on extended monitor
        if (pos.x - extOffsetX >= extScreenWidth - 30 && pos.y - extOffsetY >= extScreenHeight - 20) cornerClick();
    }
    CGPoint carbonPoint = [ExposeLib carbonPointFrom:pos];
    AXUIElementRef elementUnderCursor = [ExposeLib elementAtPoint:carbonPoint];
    NSMutableDictionary* info = [ExposeLib axInfo:elementUnderCursor]; //axTitle, axIsApplicationRunning, axPID, axIsAPplicationRunning
    if ([info[@"title"] isEqual:@"TaskSwitcher"] && [info[@"role"] isEqual:@"AXDockItem"]) return;
    runApplescript(@"screenhookClick");
//    NSLog(@"click");
}
static CGEventRef clickHook( CGEventRef clickHandler,
                              CGEventTapProxy proxy ,
                              CGEventType type ,
                              CGEventRef event ,
                              void * refcon ) {
    handleClick();
    return event;
}
void listenClicks(void) {
    CGEventMask emask;
    CFMachPortRef myEventTap;
    CFRunLoopSourceRef eventTapRLSrc;
    emask = CGEventMaskBit(kCGEventLeftMouseDown);
    myEventTap = CGEventTapCreate (
        kCGSessionEventTap, // Catch all events for current user session
        kCGTailAppendEventTap, // Append to end of EventTap list
        kCGEventTapOptionListenOnly, // We only listen, we don't modify
        emask,
        (CGEventTapCallBack) clickHook,
        nil // We need no extra data in the callback
    );
    eventTapRLSrc = CFMachPortCreateRunLoopSource( //runloop source
        kCFAllocatorDefault,
        myEventTap,
        0
    );
    CFRunLoopAddSource(// Add the source to the current RunLoop
        CFRunLoopGetCurrent(),
        eventTapRLSrc,
        kCFRunLoopDefaultMode
    );
    CFRelease(eventTapRLSrc);
}

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _systemWideAccessibilityObject = AXUIElementCreateSystemWide();
    [[[NSApp windows] firstObject] close]; //close window (GUI-free app)
    NSLog(@"%@", @"running app :)\n-------------------------------------------------------------------");
    //listen to screens
    void* userInfo = nil;
    CGDisplayRegisterReconfigurationCallback((CGDisplayReconfigurationCallBack) proc, userInfo);
    //listen to clicks
    listenClicks();
    [AppDelegate bindScreens];
}
+ (void) bindScreens { //get screen info
    NSScreen* primScreen = [AppDelegate getScreen:0];
    primaryScreenWidth = NSMaxX([primScreen frame]);
    primaryScreenHeight = NSMaxY([primScreen frame]);
    NSScreen* extScreen = [AppDelegate getScreen:1];
    extScreenWidth = [extScreen frame].size.width;
    extScreenHeight =  [extScreen frame].size.height;
    extOffsetX = [extScreen frame].origin.x;
    extOffsetY = [extScreen frame].origin.y;
}
+ (NSScreen*) getScreen: (int) screenIndex {
    NSScreen* screen = nil;
    int i = 0;
    for (NSScreen *candidate in [NSScreen screens]) {
        if (i == 0 && !NSPointInRect(NSZeroPoint, [candidate frame])) continue; //the first screen is always zeroed out, other screens have offsets
        screen = candidate;
        if (i++ == screenIndex) break;
    }
    return screen;
}
@end
