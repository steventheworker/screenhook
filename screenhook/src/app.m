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


@implementation app
//initialize app variables (onLaunch)
+ (void) initVars {
    NSLog(@"%@", @"running app :)\n-------------------------------------------------------------------");
    AppDelegate* del = [helperLib getApp];
    [del bindScreens];
    del->dockPos = [helperLib getDockPosition];
    del->dockPID = [helperLib getPID:@"com.apple.dock"]; //todo: refresh dockPID every x or so?
    
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
@end

