#import "exposelib.h"
#import "AppDelegate.h"

//config
NSDictionary* appAliases = @{
    @"Visual Studio Code": @"Code",
    @"Adobe Lightroom Classic": @"Lightroom Classic",
    @"iTerm": @"iTerm2",
    @"PyCharm CE": @"PyCharm"
};

//define
const int DEFAULTFINDERSUBPROCESSES = 7; //from my experience, after you relaunch, and move from 0 windows (1 process, since finder is ALWAYS running) to 1 window, it's usually 1windowprocess + 7 subprocesses (8 processes for 1 window     OR     1 / 7 processes for 0 windows)
const int CONTEXTDISTANCE = 150; //dock testPoint/contextmenu's approx. distance from pointer
const int DOCK_OFFSET = 5; //5 pixels

//appInfo helpers
int numWindowsMinimized(NSString* tar) {
    int numWindows = 0; //# minimized windows on active space
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll|kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    long int windowCount = CFArrayGetCount(windowList);
    for (int i = 0; i < windowCount; i++) {
        //get dictionary data
        NSDictionary *win = CFArrayGetValueAtIndex(windowList, i);
        if (![tar isEqualTo:[win objectForKey:@"kCGWindowOwnerName"]] || [[win objectForKey:@"kCGWindowLayer"] intValue] != 0) continue;
        // Get the AXUIElement windowList (e.g. elementList)
        int winPID = [[win objectForKey:@"kCGWindowOwnerPID"] intValue];
        AXUIElementRef appRef = AXUIElementCreateApplication(winPID);
        CFArrayRef elementList;
        AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute, (CFTypeRef *)&elementList);
        CFRelease(appRef);
        bool onActiveSpace = YES;
        //loop through looking for minimized && onActiveSpace
        long int numElements = elementList ? CFArrayGetCount(elementList) : 0;
        for (int j = 0; j < numElements; j++) {
            AXUIElementRef winElement = CFArrayGetValueAtIndex(elementList, j);
            CFBooleanRef winMinimized;
            AXUIElementCopyAttributeValue(winElement, kAXMinimizedAttribute, (CFTypeRef *)&winMinimized);
            if (winMinimized == kCFBooleanTrue && onActiveSpace) numWindows++;
//            CFRelease(winMinimized);
        }
    }
    CFRelease(windowList);
    return numWindows;
}



@implementation ExposeLib
+ (AXUIElementRef) elementAtPoint:(CGPoint) carbonPoint {
    AXUIElementRef elementUnderCursor = NULL;
    AXUIElementCopyElementAtPosition([ExposeLib getApp]->_systemWideAccessibilityObject, carbonPoint.x, carbonPoint.y, &elementUnderCursor);
    return elementUnderCursor;
}
+ (NSApplication*) sharedApplication {
    return [NSApplication sharedApplication];
}
+ (NSString*) getDockPosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults persistentDomainForName:@"com.apple.dock"] valueForKey:@"orientation"];
}
+ (NSDictionary*) appInfo:(NSString*) owner {
    NSMutableArray* windows = [ExposeLib getWindowsForOwner:owner]; //on screen windows
    //hidden & minimized (off screen windows)
    BOOL isHidden = NO;
    BOOL isMinimized = NO;
    if ([ExposeLib runningAppFromAxTitle:owner].isHidden) isHidden = YES;
    if (numWindowsMinimized(owner)) isMinimized = YES;
    //add missing window(s) (a window can be hidden & minimized @ same time (don't want two entries))
    if (!isHidden && isMinimized) [windows addObject:@123456789]; //todo: properly add these two windowTypes to windowNumberList, but works
    return @{
        @"windows": windows,
        @"numWindows": [NSNumber numberWithInt:(int)[windows count]],
        @"isHidden": [NSNumber numberWithBool:isHidden],
        @"isMinimized": [NSNumber numberWithBool:isMinimized],
    };
}
+ (NSMutableDictionary*) axInfo:(AXUIElementRef)el {
    NSString *axTitle = nil;
    AXUIElementCopyAttributeValue(el, kAXTitleAttribute, (void *)&axTitle);
    axTitle = appAliases[axTitle] ? appAliases[axTitle] : axTitle; //app's with alias work weird (eg: VScode = Code)
    NSNumber *axIsApplicationRunning;
    AXUIElementCopyAttributeValue(el, kAXIsApplicationRunningAttribute, (void *)&axIsApplicationRunning);
    pid_t axPID;
    AXUIElementGetPid(el, &axPID);
    NSString *role;
    AXUIElementCopyAttributeValue(el, kAXRoleAttribute, (void*)&role);
    AXValueRef sizeRef;
    CGSize size;
    AXUIElementCopyAttributeValue(el, kAXSizeAttribute, (void*)&sizeRef);
    if (el) AXValueGetValue(sizeRef, kAXValueCGSizeType, &size);
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                !axTitle ? @"" : axTitle, @"title",
                                @([axIsApplicationRunning intValue]), @"running",
                                @(axPID), @"PID",
                                !role ? @"" : role, @"role",
                                @(size.width), @"width",
                                @(size.height), @"height"
                                 , nil];
}
+ (pid_t) getPID: (NSString*) tar {
    NSArray *appList = [[NSWorkspace sharedWorkspace] runningApplications];
    for (int i = 0; i < appList.count; i++) {
        NSRunningApplication *cur = appList[i];
        if (![tar isEqualTo: cur.bundleIdentifier]) continue;
        return cur.processIdentifier;
    }
    return 0;
}
+ (NSRunningApplication*) runningAppFromAxTitle:(NSString*) tar {
    NSArray *appList = [[NSWorkspace sharedWorkspace] runningApplications];
    for (int i = 0; i < appList.count; i++) {
        NSRunningApplication *cur = appList[i];
        if (![tar isEqualTo: cur.localizedName]) continue;
        return cur;
    }
    return nil;
}
+ (NSMutableArray*) getWindowsForOwner: (NSString *)owner {
    if (!owner || [@"" isEqual:owner]) return nil;
    if ([ExposeLib runningAppFromAxTitle:owner].isHidden) return [NSMutableArray new]; //this program doesn't mess with hidden apps
    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
    NSMutableArray *ownerWindowList = [NSMutableArray new];
    long int windowCount = CFArrayGetCount(windowList);
    for (int i = 0; i < windowCount; i++) {
        NSDictionary *win = CFArrayGetValueAtIndex(windowList, i);
        if (![owner isEqualTo:[win objectForKey:@"kCGWindowOwnerName"]]) continue;
        [ownerWindowList addObject:win];
    }
    CFRelease(windowList);
    return ownerWindowList;
}
+ (NSMutableArray*) getWindowsForOwnerPID:(pid_t) PID {
  if (!PID) return nil;
  CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
  NSMutableArray *ownerWindowList = [NSMutableArray new];
  long int windowCount = CFArrayGetCount(windowList);
  for (int i = 0; i < windowCount; i++) {
      NSDictionary *win = CFArrayGetValueAtIndex(windowList, i);
      NSNumber* curPID = [win objectForKey:@"kCGWindowOwnerPID"];
      if (PID != (pid_t) [curPID intValue]) continue;
      [ownerWindowList addObject:win];
  }
  CFRelease(windowList);
  return ownerWindowList;
}
+ (void) triggerKeycode:(CGKeyCode) key {
    CGEventSourceRef src = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
    CGEventRef down = CGEventCreateKeyboardEvent(src, key, true);
    CGEventRef up = CGEventCreateKeyboardEvent(src, key, false);
    CGEventPost(kCGHIDEventTap, down);
    CGEventPost(kCGHIDEventTap, up);
    CFRelease(down);
    CFRelease(up);
    CFRelease(src);
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
+ (CGPoint) carbonPointFrom:(NSPoint) cocoaPoint {
    NSScreen* screen = [ExposeLib getScreen:0];
    float menuScreenHeight = NSMaxY([screen frame]);
    return CGPointMake(cocoaPoint.x,  menuScreenHeight - cocoaPoint.y);
}
+ (AppDelegate *) getApp {return ((AppDelegate *)[[ExposeLib sharedApplication] delegate]);}
@end
