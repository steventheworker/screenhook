//
//  app.m
//  DockAltTab
//
//  Created by Steven G on 5/9/22.
//

#import "app.h"
#import "helperLib.h"
#import "timer.h"

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

@implementation app
//initialize app variables (onLaunch)
+ (void) init {
    NSLog(@"%@", @"running app :)\n-------------------------------------------------------------------");
    // permissions
    AppDelegate* del = [helperLib getApp];
    del->_systemWideAccessibilityObject = AXUIElementCreateSystemWide();
    [helperLib listenMouseDown]; // ask for input monitoring first
    [helperLib listenMouseUp]; // ask for input monitoring first
    askForAccessibility();
    [del measureScreens]; // get all screen values onLaunch
    
    // permission-free events
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
    
    [[timer alloc] init]; // start timer
    
    // init UI
    if (del->runningApps[@"BTT"]) [[del->BTTState cell] setTitle:@"Checking if afterBTTLaunched..."];
}
+ (BOOL) isSpotlightOpen : (BOOL) isAlfred {
    return ![[helperLib runScript: [NSString stringWithFormat: @"tell application \"System Events\" to tell process \"%@\" to count of windows", isAlfred ? @"Alfred" : @"Spotlight"]] isEqual:@"0"];
}
@end

