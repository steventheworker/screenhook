//
//  WindowManager.h
//  screenhook
//
//  Created by Steven G on 11/8/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Window.h"

NS_ASSUME_NONNULL_BEGIN

extern AXError _AXUIElementGetWindow(AXUIElementRef element, CGWindowID *identifier); // add private api fn (axwindow -> cgiwindownumber)
typedef enum {exposeClosed, DesktopExpose, AppExpose, MissionControl} exposeTypes;

@interface WindowManager : NSObject
+ (void) init;
+ (NSArray<Window*>*) windows;
+ (int) exposeType;
+ (int) exposeTick;

+ (void) initialDiscovery;
+ (void) observeWindow: (AXUIElementRef) axWindow : (NSRunningApplication*) app : (CGWindowID) winNum;
+ (void) observeApp: (NSRunningApplication*) app;
+ (void) observerCallback: (AXObserverRef) observer : (AXUIElementRef) elementRef : (CFStringRef) notification : (void*) refcon;
+ (void) windowObserverCallback: (AXObserverRef) observer : (AXUIElementRef) elementRef : (CFStringRef) notification : (void*) refcon;
+ (void) spaceChanged: (NSNotification*) note;
+ (void) appLaunched: (NSNotification*) note;
+ (void) appTerminated: (NSNotification*) note;
+ (void) updateSpaces;
@end

NS_ASSUME_NONNULL_END
