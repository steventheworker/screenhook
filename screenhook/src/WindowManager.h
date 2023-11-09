//
//  WindowManager.h
//  screenhook
//
//  Created by Steven G on 11/8/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

extern AXError _AXUIElementGetWindow(AXUIElementRef element, CGWindowID *identifier); // add private api fn (axwindow -> cgiwindownumber)
typedef enum {exposeClosed, DesktopExpose, AppExpose, MissionControl} exposeTypes;

@interface WindowManager : NSObject
+ (void) init;
+ (int) exposeType;
+ (int) exposeTick;

+ (int) initialDiscovery;
+ (void) observeWindow: (AXUIElementRef) axWindow : (pid_t) appPID : (CGWindowID) winNum;
+ (void) observeApp: (NSRunningApplication*) app;
+ (void) observerCallback: (AXObserverRef) observer : (AXUIElementRef) elementRef : (CFStringRef) notification : (void*) refcon;
+ (void) windowObserverCallback: (AXObserverRef) observer : (AXUIElementRef) elementRef : (CFStringRef) notification : (void*) refcon;
+ (void) spaceChanged: (NSNotification*) note;
@end

NS_ASSUME_NONNULL_END
