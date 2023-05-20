//
//  helperLib.h
//  screenhook
//
//  Created by Steven G on x/x/22.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

NS_ASSUME_NONNULL_BEGIN
@interface helperLib : NSObject {}
+ (NSString*) getDockPosition;
+ (pid_t) getPID: (NSString*) tar;
+ (NSDictionary*) appInfo: (NSString*) owner;
+ (NSScreen*) getScreen: (int) screenIndex;
+ (CGPoint) carbonPointFrom: (NSPoint) cocoaPoint;
+ (void) triggerKeycode: (CGKeyCode) key;
+ (NSRunningApplication*) runningAppFromAxTitle: (NSString*) tar;
+ (int) numWindowsMinimized: (NSString *)owner;
+ (NSMutableArray*) getWindowsForOwner: (NSString *)owner;
+ (NSMutableArray*) getWindowsForOwnerOnScreen: (NSString *)owner;
+ (NSMutableArray*) getWindowsForOwnerPID: (pid_t) PID;
+ (NSMutableArray*) getRealFinderWindows;
+ (NSApplication *) sharedApplication;
+ (AXUIElementRef) elementAtPoint: (CGPoint) carbonPoint;
+ (NSDictionary*) axInfo: (AXUIElementRef) el;
+ (void) listenScreens;
+ (void) listenMouseDown;
+ (void) listenMouseUp;
+ (void) listenMask: (CGEventMask) emask : (CGEventTapCallBack) handler;
+ (AppDelegate *) getApp;
+ (void) killDock;
+ (void) dockSetting: (CFStringRef) pref : (BOOL) val;
+ (NSString*) twoSigFigs: (float) val;
+ (BOOL) dockautohide;
+ (NSString*) runScript: (NSString*) scriptTxt;
+ (void) runAppleScriptAsync: (NSString*) scriptTxt : (void(^)(NSString*)) _cb;
+ (void) runAppleScript: (NSString*) scptPath;
+ (void) trackFrontApp: (NSNotification*) notification;
+ (void) listenRunningAppsChanged;
+ (void) nextSpace;
+ (void) previousSpace;
@end
NS_ASSUME_NONNULL_END
