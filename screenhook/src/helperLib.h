//
//  helperLib.h
//  DockAltTab
//
//  Created by Steven G on 5/9/22.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

enum dockPositions {DockLeft, DockBottom, DockRight};

//missing attributes
#define kAXPIDAttribute CFSTR("AXPID") //dunno why AXUIElementGetPid is so special (no way to get pid with AXUIElementCopyAttributeValue)
#define kAXFullscreenAttribute CFSTR("kAXFullscreenAttribute")
#define kAXStatusLabelAttribute CFSTR("kAXStatusLabelAttribute")

NS_ASSUME_NONNULL_BEGIN
@interface helperLib : NSObject {}
/* AXUIElement */
+ (void) setSystemWideEl: (AXUIElementRef) el;
+ (AXUIElementRef) elementAtPoint: (CGPoint) pt;
+ (NSDictionary*) elementDict: (AXUIElementRef) el : (NSDictionary*) attributeDict;
/* events*/
+ (CFMachPortRef) listenMask: (CGEventMask) emask : (CGEventTapCallBack) handler;
+ (CFMachPortRef) listenOnlyMask : (CGEventMask) emask : (CGEventTapCallBack) handler;
+ (CFMachPortRef) _listenMask : (CGEventMask) emask : (CGEventTapCallBack) handler : (BOOL) listenDefault;
+ (void) on: (NSString*) eventKey : (BOOL (^)(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void* refcon)) callback;
+ (void) stopListening;
+ (NSString*) eventKeyWithEventType: (CGEventType) type;
/* screens*/
+ (void) listenScreens;
+ (void) proc: (CGDirectDisplayID) display : (CGDisplayChangeSummaryFlags) flags : (void*) userInfo;
+ (void) processScreens;
+ (NSScreen*) screenAtCGPoint: (CGPoint) pt;
+ (NSScreen*) screenAtNSPoint: (NSPoint) pt;
+ (NSPoint) NSPointFromCGPoint: (CGPoint) pt;
+ (CGPoint) CGPointFromNSPoint: (NSPoint) pt;
+ (NSScreen*) primaryScreen;
/* trigger/simulate events */
+ (void) toggleDock;
+ (void) killDock;
+ (void) sendKey: (int) keyCode;
+ (void) requestNotificationPermission:  (void(^)(BOOL granted)) cb;
+ (void) sendNotificationWithID: (NSString*) notificationID : (NSString*) title : (NSString*) message;
+ (void) sendNotification: (NSString*) title : (NSString*) message;
+ (NSArray*) $: (NSView*) container : (NSString*) identifier;
+ (NSView*) $0: (NSView*) container : (NSString*) identifier;
+ (CGRect) rectWithDict: (NSDictionary*) dict;
+ (BOOL) dockAutohide;
+ (int) dockPos;
+ (CGRect) dockRect;
+ (AXUIElementRef) dockAppElementFromDockChild: (AXUIElementRef) dockChild;
+ (CGPoint) normalizePointForDockGap: (CGPoint) pt : (int) dockPos;
+ (NSRunningApplication*) appWithBID: (NSString*) tarBID;
+ (NSRunningApplication*) appWithPID: (pid_t) tarPID;
+ (void) activateWindow: (NSWindow*) window;
+ (void) activateApp: (NSURL*) tarAppURL : (void(^)(NSRunningApplication* app, NSError* error)) cb;
+ (NSDictionary*) modifierKeys;
+ (NSString*) applescript: (NSString*) scriptTxt;
+ (void) applescriptAsync: (NSString*) scriptTxt : (void(^)(NSString*)) cb;
+ (BOOL) isSparkleUpdaterOpen;
+ (NSString*) appVersion;
+ (NSString*) dictionaryStringOneLine : (NSDictionary*) dict : (BOOL) flattest;
+ (BOOL) isNaN : (NSString*) input;
+ (BOOL) isBackgroundApp: (NSRunningApplication*) app;
+ (void) restartApp;
+ (void) openAppExpose;
+ (void) openDesktopExpose;
+ (void) openMissionControl;
@end
NS_ASSUME_NONNULL_END
