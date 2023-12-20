//
//  WindowManager.h
//  screenhook
//
//  Created by Steven G on 11/8/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Window.h"
#import "Application.h"

NS_ASSUME_NONNULL_BEGIN

extern AXError _AXUIElementGetWindow(AXUIElementRef element, CGWindowID *identifier); // add private api fn (axwindow -> cgiwindownumber)
typedef enum {exposeClosed, DesktopExpose, AppExpose, MissionControl} exposeTypes;

@interface WindowManager : NSObject
+ (void) init: (void(^)(void)) cb;
+ (NSArray<Window*>*) windows;
+ (Application*) appWithBID: (NSString*) bid;
+ (int) exposeType;
+ (int) exposeTick;

+ (void) initialDiscovery: (void(^)(void)) cb;
+ (void) observeWindow: (id) axWindow : (Application*) app : (CGWindowID) winNum;
+ (void) observeApp: (Application*) app;
+ (void) stopObservingApp: (Application*) app;
+ (void) stopObservingWindow: (Window*) app;
+ (void) appObserverCallback: (AXObserverRef) observer : (id) elementRef : (CFStringRef) notification : (void*) refcon;
+ (void) windowObserverCallback: (AXObserverRef) observer : (id) elementRef : (CFStringRef) notification : (void*) refcon;
+ (void) spaceChanged: (NSNotification*) note;
+ (void) appLaunched: (NSRunningApplication*) app;
+ (void) appTerminated: (NSRunningApplication*) app;
+ (void) updateSpaces;
@end

NS_ASSUME_NONNULL_END
