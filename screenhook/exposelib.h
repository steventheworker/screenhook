#import <Cocoa/Cocoa.h>

@interface ExposeLib : NSObject {}
+ (NSString*) getDockPosition;
+ (pid_t) getPID: (NSString*) tar;
+ (NSDictionary*) appInfo: (NSString*) owner;
+ (NSScreen*) getScreen: (int) screenIndex;
+ (CGPoint) carbonPointFrom: (NSPoint) cocoaPoint;
+ (void) triggerKeycode: (CGKeyCode) key;
+ (NSRunningApplication*) runningAppFromAxTitle: (NSString*) tar;
+ (NSMutableArray*) getWindowsForOwner: (NSString *)owner;
+ (NSMutableArray*) getWindowsForOwnerPID: (pid_t) PID;
+ (NSApplication *) sharedApplication;
+ (AXUIElementRef) elementAtPoint: (CGPoint) carbonPoint;
+ (NSMutableDictionary*) axInfo: (AXUIElementRef) el;
@end
