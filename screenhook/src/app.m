//
//  app.m
//  DockAltTab
//
//  Created by Steven G on 5/9/22.
//

#import "app.h"
#import "helperLib.h"

//config
const NSString* versionLink = @"https://dockalttab.netlify.app/currentversion.txt";
const float TICK_DELAY = 0.16666665; // 0.33333 / 2   seconds
const float DELAY_MAX = 2; // seconds

//define
const int CONTEXTDISTANCE = 150; //dock testPoint/contextmenu's approx. distance from pointer
const int DOCK_OFFSET = 5; //5 pixels

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
+ (void) initVars {
    NSLog(@"%@", @"running app :)\n-------------------------------------------------------------------");
    // permissions
    AppDelegate* del = [helperLib getApp];
    del->_systemWideAccessibilityObject = AXUIElementCreateSystemWide();
    [helperLib listenMouseDown]; // ask for input monitoring first
    [helperLib listenMouseUp]; // ask for input monitoring first
    askForAccessibility();
    [del bindScreens]; // get all screen values onLaunch
    
    // permission-free events
    [helperLib listenScreens];
    
    // functional variables
    del->dockPos = [helperLib getDockPosition];
    del->dockPID = [helperLib getPID:@"com.apple.dock"]; //todo: refresh dockPID every x or so?
    del->runningApps = @{
        @"Alfred": @([helperLib getPID:@"com.runningwithcrayons.Alfred"]),
        @"AltTab": @([helperLib getPID:@"com.steventheworker.alt-tab-macos"]),
        @"DockAltTab": @([helperLib getPID:@"com.steventheworker.DockAltTab"]),
        @"BTT": @([helperLib getPID:@"com.hegenberg.BetterTouchTool"]),
        @"Firefox": @([helperLib getPID:@"org.mozilla.firefox"]),
//        @"Finder": @([helperLib getPID:@"com.apple.finder"]),
    };
}

/* UI */
/* utilities that depend on (AppDelegate *) */
+ (BOOL) contextMenuExists:(CGPoint) carbonPoint : (NSDictionary*) info {
    AppDelegate* del = [helperLib getApp];
    if ([info[@"role"] isEqual:@"AXMenuItem"] || [info[@"role"] isEqual:@"AXMenu"]) return YES;
    int multiplierX = [del->dockPos isEqual:@"left"] || [del->dockPos isEqual:@"right"] ? ([del->dockPos isEqual:@"left"] ? 1 : -1) : 0;
    int multiplierY = [del->dockPos isEqual:@"bottom"] ? -1 : 0;
    CGPoint testPoint = CGPointMake(carbonPoint.x + multiplierX * CONTEXTDISTANCE, carbonPoint.y + multiplierY * CONTEXTDISTANCE); //check if there is an open AXMenu @ testPoint next to the mouseLocation (DockLeft +x, DockRight -x, DockBottom -y)
    NSDictionary* testInfo = [helperLib axInfo:[helperLib elementAtPoint:testPoint]];
//    CFRelease(testPoint);
    if ([testInfo[@"role"] isEqual:@"AXMenuItem"] || [testInfo[@"role"] isEqual:@"AXMenu"]) return YES;
    return NO;
}
+ (void) focusDock {
    NSLog(@"focusDock");
    NSString* scriptTxt = @"tell application \"System Events\"\n\
        key down 63\n\
    delay 0.333\n\
        key code 0\n\
        key up 63\n\
    end tell";
    [helperLib runScript: scriptTxt];
}
+ (float) maxDelay {return DELAY_MAX;}
+ (NSString*) getCurrentVersion {return [helperLib get: (NSString*) versionLink];}
+ (BOOL) isSpotlightOpen : (BOOL) isAlfred {
    return ![[helperLib runScript: [NSString stringWithFormat: @"tell application \"System Events\" to tell process \"%@\" to count of windows", isAlfred ? @"Alfred" : @"Spotlight"]] isEqual:@"0"];
}
@end

