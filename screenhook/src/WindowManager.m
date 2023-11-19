//
//  WindowManager.m
//  screenhook
//
//  Created by Steven G on 11/8/23.
//

#import "WindowManager.h"
#import "globals.h"
#import "helperLib.h"
#import "Spaces.h"

const int ACTIVATION_MILLISECONDS = 30; //how long to wait to activate after [app unhide]

int cgsMainConnectionId;
CGWindowID focusedWindowID;
int focusedPID;

int activationT = ACTIVATION_MILLISECONDS; //on spaceswitch: wait longer
int exposeType = 0; //exposeTypes enum
CFArrayRef visibleWindows = nil; //CGWindow's
CFArrayRef lastVisibleWindows = nil;
NSMutableDictionary* closedWindows; //key = appPID, value = @{kcgwindownumber1: winDict1, kcgwindownumber2: winDict2, ...}
NSMutableDictionary<NSString*, NSValue*>* observers;
NSArray* AppObserverNotifications;
NSArray* WindowObserverNotifications;
NSMutableArray* windows;

void loadVisibleWindows(void) {
//    NSLog(@"regen visible windows");
    lastVisibleWindows = visibleWindows ? visibleWindows : (CFArrayRef)@[];
    visibleWindows = CGWindowListCopyWindowInfo(kCGWindowListOptionAll|kCGWindowListExcludeDesktopElements/* kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements */, kCGNullWindowID);
}
int getExposeType(void) {
    loadVisibleWindows();
    long int winCount = CFArrayGetCount(visibleWindows);
    int specialWinCount = 0;
    for (int i = 0; i < winCount; i++) {
        NSDictionary* winDict = CFArrayGetValueAtIndex(visibleWindows, i);
        BOOL isOnscreen = [winDict[(id)kCGWindowIsOnscreen] boolValue];
        if (!isOnscreen) continue;
        NSString* owner = [winDict objectForKey:@"kCGWindowOwnerName"];
        if ([owner isEqual: @"Dock"]) {
            if ([winDict[(id)kCGWindowLayer] intValue] != 20) specialWinCount++; //windows with ownerName=Dock, if owner="Dock" && kCGWindowName != "Dock" => special dock window (exposé / mission control / desktop exposé)....        layer 20 is the dock window titled "Dock" (it doesn't exist w/ autohidden dock until you put mouse over area that reveal it, so just ignore it)         //todo: distinguish desktop exposé
//            NSLog(@"%@", winDict);
        }
    }
    
    
    /* specialWinCount (windows added on hover = layer 20 (mission control), layer 0 (exposé))
     // 1 can be desktop exposé
     // 1 can be app exposé (before window hover)
     // 2 can be app exposé (after window hover)
     // 2 can be mission control (before window hover)
     // 3 can be  mission control (after window hover) */
    if (!specialWinCount || specialWinCount > exposeType) exposeType = specialWinCount; // suddenly hovering to a different specialWinCount always indicates the next one on the above list (can't go backwards, just reset to 0)
//    NSLog(@"%d", exposeType);
    return exposeType;
}

void onLaunchTrackFrontmostWindow(CFArrayRef beforeWindows, NSRunningApplication* app) {
    BOOL foundNew = NO;
    AXUIElementRef appel = AXUIElementCreateApplication(app.processIdentifier);
    //add window observers
    NSArray* wins = [helperLib elementDict: appel : @{@"windows" : (id)kAXWindowsAttribute}][@"windows"];
    for (NSValue* pointerVal in wins) {
        AXUIElementRef el;
        [pointerVal getValue: &el];
        if (!el) continue;
        AXUIElementRef windowElement = (AXUIElementRef)([pointerVal pointerValue]);
        CGWindowID winNum;
        _AXUIElementGetWindow(windowElement, &winNum);
        BOOL foundEntry = NO;
        for (Window* win in windows) if (win->winNum == winNum) {foundEntry = YES;break;} //since cannot break/continue outerloop from inner loop, set flag to continue outer loop
        if (foundEntry) continue; else foundNew = YES;
        [WindowManager observeWindow: windowElement : app : winNum];
    }
    if (foundNew) loadVisibleWindows();
    if (focusedPID == app.processIdentifier) {
        AXUIElementRef appel = AXUIElementCreateApplication(app.processIdentifier);
        AXUIElementRef focusedWindow = [[helperLib elementDict: appel : @{@"focusedWindow": (id)kAXFocusedWindowAttribute}][@"focusedWindow"] pointerValue];
        CGWindowID windowID;
        _AXUIElementGetWindow(focusedWindow, &windowID);
        focusedWindowID = windowID;
    }
}

static void axObserverCallback(AXObserverRef observer, AXUIElementRef elementRef, CFStringRef notification, void *refcon) {[WindowManager observerCallback: observer : elementRef : notification : refcon];}
static void axWindowObserverCallback(AXObserverRef observer, AXUIElementRef elementRef, CFStringRef notification, void *refcon) {[WindowManager windowObserverCallback: observer : elementRef : notification : refcon];}
@implementation WindowManager
+ (void) init {
    observers = [NSMutableDictionary dictionary];
    windows = [NSMutableArray array];
    closedWindows = [NSMutableDictionary dictionary];
    /* activationPolicy & other copied from command-tab (trackfrontapp)
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackFrontApp:) name:NSApplicationDidBecomeActiveNotification object:NSApp];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackFrontApp:) name:NSApplicationDidResignActiveNotification object:NSApp];
     [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(trackFrontApp:) name:@"com.apple.HIToolbox.menuBarShownNotification" object:nil]; */
    AppObserverNotifications = @[(id)kAXApplicationActivatedNotification, (id)kAXMainWindowChangedNotification, (id)kAXFocusedWindowChangedNotification, (id)kAXWindowCreatedNotification, (id)kAXApplicationHiddenNotification, (id)kAXApplicationShownNotification];
    WindowObserverNotifications = @[(id)kAXUIElementDestroyedNotification, (id)kAXTitleChangedNotification, (id)kAXWindowMiniaturizedNotification, (id)kAXWindowDeminiaturizedNotification, (id)kAXWindowResizedNotification, (id)kAXWindowMovedNotification];
    loadVisibleWindows();
    [self initialDiscovery];
}
+ (NSArray<Window*>*) windows {return windows;}
+ (int) exposeType {return exposeType;}
+ (int) exposeTick {
//    NSLog(@"exposeTick %d", getExposeType());
    return getExposeType();
}

+ (void) initialDiscovery {
    //initial discovery
    [Spaces init: (cgsMainConnectionId = CGSMainConnectionID())];
    NSArray* otherSpaces = [Spaces otherSpaces];
    if (otherSpaces.count) {
        NSArray* windowsOnCurrentSpace = [Spaces windowsInSpaces: @[@([Spaces currentSpaceId])] : YES];
        NSArray* windowsOnOtherSpaces = [Spaces windowsInSpaces: otherSpaces : YES];
        NSMutableSet* otherSpacesSet = [NSMutableSet setWithArray: windowsOnOtherSpaces];
        [otherSpacesSet minusSet: [NSSet setWithArray: windowsOnCurrentSpace]];
        NSArray* windowsOnlyOnOtherSpaces = [otherSpacesSet allObjects];
        if (windowsOnlyOnOtherSpaces.count > 0) {
            // on initial launch, we use private APIs to bring windows from other spaces into the current space, observe them, then remove them from the current space
            //            CGSAddWindowsToSpaces(cgsMainConnectionId, (__bridge CFArrayRef)(windowsOnlyOnOtherSpaces), (__bridge CFArrayRef)(@[@([Spaces currentSpaceId])]));
            
            //since these two private api's stopped working (supposedly on introduction of monterey), workaround: hidden apps show windows from all spaces, take advantage of this weird quirk
            NSArray<NSRunningApplication*>* runningApps = [NSWorkspace sharedWorkspace].runningApplications;
            NSRunningApplication* originallyFrontmost = [[NSWorkspace sharedWorkspace] frontmostApplication];
            NSMutableArray<NSRunningApplication*>* originalVisibleApps = [NSMutableArray array];
            NSRunningApplication* finder = [helperLib appWithBID: @"com.apple.finder"];
            BOOL finderWasHidden = finder.isHidden;
            if (finder.isHidden) [finder unhide]; //we'll observe finder after
            //            if (originallyFrontmost == finder)
            for (NSRunningApplication *app in runningApps) {
                if (app == finder) continue;
                if (!app.isHidden) {
                    [originalVisibleApps addObject: app];
                    [app hide];
                }
            }
            setTimeout(^ {
                //observe other apps
                NSLog(@"------------OBSERVE OTHER SPACES------------");
                for (NSRunningApplication* app in [[NSWorkspace sharedWorkspace] runningApplications]) [self observeApp: app];
                NSLog(@"------------OBSERVE OTHER SPACES------------");
                for (NSRunningApplication *app in originalVisibleApps) [app unhide]; // CGSRemoveWindowsFromSpaces(cgsMainConnectionId, (__bridge CFArrayRef)(windowsOnlyOnOtherSpaces), (__bridge CFArrayRef)(@[@([Spaces currentSpaceId])]));
                [finder hide];
                setTimeout(^{//observe finder
                    [self observeApp: finder];
                    if (!finderWasHidden) [finder unhide]; //restore finder visibility
                }, 70);
            }, 70);
//            setTimeout(^{[self activateApp: originallyFrontmost];}, 200); //restore frontmost
            return;
        }
    }
}
+ (void) windowObserverCallback: (AXObserverRef) observer : (AXUIElementRef) el : (CFStringRef) notification : (void*) refcon {
    NSString* type = (__bridge NSString *)notification;
    int appPID = [[helperLib elementDict: el : @{@"pid": (id)kAXPIDAttribute}][@"pid"] intValue];
    NSLog(@"observe window type %@", type);
    if ([type isEqual: @"AXUIElementDestroyed"]) { // window closed
        NSLog(@"focusedpid %d apppid %d focusedwindowid", focusedPID, focusedWindowID);
        if (focusedPID == appPID) {
            //check if tooltip-like window is what actually closed
            AXUIElementRef appel = AXUIElementCreateApplication(appPID);
            AXUIElementRef focusedWindow = [[helperLib elementDict: appel : @{@"focusedWindow": (id)kAXFocusedWindowAttribute}][@"focusedWindow"] pointerValue];
            CGWindowID windowID;
            _AXUIElementGetWindow(focusedWindow, &windowID);
            if (focusedWindowID == windowID) return NSLog(@"window closed false positive (tooltip-like window)");

            long int winCount = CFArrayGetCount(visibleWindows);
            for (int i = 0; i < winCount; i++) {
                NSDictionary* winDict = CFArrayGetValueAtIndex(visibleWindows, i);
                if ([winDict[(id)kCGWindowNumber] intValue] == focusedWindowID) {
                    NSLog(@"closed cgdict %@", winDict);
                }
            }

            NSMutableDictionary* dictEntry = closedWindows[[NSString stringWithFormat: @"%d", appPID]];
            if (!dictEntry) {
                closedWindows[[NSString stringWithFormat: @"%d", appPID]] = [NSMutableDictionary dictionary];
                dictEntry = closedWindows[[NSString stringWithFormat: @"%d", appPID]];
            }
            dictEntry[[NSString stringWithFormat: @"%d", focusedWindowID]] = @1;
            NSLog(@"closed win %d", focusedWindowID);
            //stop observing
            [self stopObservingWindow: appPID : focusedWindowID];
        } else NSLog(@"front window tracking went wrong");
    } else {
        loadVisibleWindows();
        CGWindowID windowID;
        _AXUIElementGetWindow(el, &windowID);
        if (windowID) {
            focusedWindowID = windowID;
            focusedPID = appPID;
        } else {
//            AXUIElementRef appel = AXUIElementCreateApplication(appPID);
//            AXUIElementRef focusedWindow = [[helperLib elementDict: appel : @{@"focusedWindow": (id)kAXFocusedWindowAttribute}][@"focusedWindow"] pointerValue];
//            CGWindowID windowID;
//            _AXUIElementGetWindow(focusedWindow, &windowID);
//            focusedWindowID = windowID;
//            focusedPID = appPID;
        }
        NSLog(@"window observe winid %d - %@", windowID, notification);
    }
}
+ (void) observerCallback: (AXObserverRef) observer : (AXUIElementRef) el : (CFStringRef) note : (void*) refcon {
    NSString* type = (__bridge NSString *)note;
    int appPID = [[helperLib elementDict: el : @{@"pid": (id)kAXPIDAttribute}][@"pid"] intValue];
    if ([type isEqual: @"AXApplicationActivated"] || [type isEqual: @"AXApplicationHidden"]) {
        if ([type isEqual: @"AXApplicationHidden"]) appPID = [[NSWorkspace sharedWorkspace] frontmostApplication].processIdentifier;
        AXUIElementRef appel = AXUIElementCreateApplication(appPID);
        AXUIElementRef focusedWindow = [[helperLib elementDict: appel : @{@"focusedWindow": (id)kAXFocusedWindowAttribute}][@"focusedWindow"] pointerValue];
        CGWindowID windowID;
        _AXUIElementGetWindow(focusedWindow, &windowID);
        focusedWindowID = windowID;
        focusedPID = appPID;
        NSLog(@"focusedwindowid %d", focusedWindowID);
    } else {
        CFRetain(el);
        setTimeout(^{
            loadVisibleWindows();
            CGWindowID windowID;
            _AXUIElementGetWindow(el, &windowID);
            if (windowID) {
                focusedWindowID = windowID;
                focusedPID = appPID;
            }
//            NSLog(@"app observer - winid %d - %@", windowID, notification);
            
            if ([type isEqual: @"AXWindowCreated"]) [self observeWindow: el : [helperLib appWithPID: appPID] : windowID];
        }, 333); // delay because: event order is focused, mainwindow, THEN destroy element is called (so the focusedWindow isn't accurate (when detecting which window closed), since it activates another window before destroying)
        //todo wait less long (100ms worked, but not for scriptable AltTab)
    }
}
+ (void) observeWindow: (AXUIElementRef) axWindow : (NSRunningApplication*) app : (CGWindowID) winNum {
    for (Window* win in windows) if (win->winNum == winNum) return /*NSLog(@"observer already exists for window %d", winNum)*/;
    if (winNum == 0) return; //finder desktop window (or windows created before login?) cannot be observed / not a "real" window
    // Create an observer
    AXObserverRef observer;
    AXError err = AXObserverCreate(app.processIdentifier, axWindowObserverCallback, &observer);
    if (err) return NSLog(@"err1 %@ - %d", [helperLib appWithPID: app.processIdentifier].localizedName, err);
    NSLog(@"%@", axWindow);
    // Add notifications to the observer
    for (NSString* notification in WindowObserverNotifications) {
        err = AXObserverAddNotification(observer, axWindow, (__bridge CFStringRef)notification, (__bridge void * _Nullable)(self));
        if (err) {NSLog(@"Error adding %@ notification for '%@' - %d", notification, app.localizedName, err);}
    }
    // Register the observer with the run loop
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
    NSLog(@"window observers added for %d", winNum);
    [windows addObject: [Window init: app : axWindow : winNum : observer]];
}
+ (void) observeApp: (NSRunningApplication*) app {
    if (app.activationPolicy == NSApplicationActivationPolicyProhibited || [helperLib isBackgroundApp: app]) return /* NSLog(@"skip %@", app.localizedName) */;
    AXUIElementRef appel = AXUIElementCreateApplication(app.processIdentifier);
    if (!observers[[NSString stringWithFormat: @"%d", app.processIdentifier]]) {
        AXObserverRef observer;
        AXError err = AXObserverCreate(app.processIdentifier, axObserverCallback, &observer);
        if (err) return NSLog(@"err1 %@ - %d", app.localizedName, err);
        for (NSString* notification in AppObserverNotifications) {
            err = AXObserverAddNotification(observer, appel, (__bridge CFStringRef)notification, (__bridge void * _Nullable)(self));
            if (err) {NSLog(@"Error adding %@ notification for '%@' - %d", notification, app.localizedName, err);}
        }
        CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
        NSLog(@"Observers created for '%@'", app.localizedName);
        observers[[NSString stringWithFormat: @"%d", app.processIdentifier]] = [NSValue valueWithPointer: observer];
    }
    
    //add window observers
    NSArray* windows = [helperLib elementDict: appel : @{@"windows" : (id)kAXWindowsAttribute}][@"windows"];
    for (NSValue* pointerVal in windows) {
        AXUIElementRef el;
        [pointerVal getValue: &el];
        if (!el) return;
        AXUIElementRef windowElement = (AXUIElementRef)([pointerVal pointerValue]);
        CGWindowID winNum;
        _AXUIElementGetWindow(windowElement, &winNum);
        [self observeWindow: windowElement : app : winNum];
    }
}
+ (void) stopObservingWindow: (pid_t) appPID : (CGWindowID) winNum {
    for (int i = (int)windows.count - 1; i > -1; i--) {
        Window* win = windows[i];
        if (win->winNum == winNum) {
            if (!win->observer) {
                NSLog(@"\nWINDOW W/O OBSERVER - APP: %@\n", [helperLib appWithPID: appPID]);
                [windows removeObjectAtIndex: i];
                break;
            }
            CFRunLoopRemoveSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(win->observer), kCFRunLoopDefaultMode);
            win->observer = nil;
            [windows removeObjectAtIndex: i];
            NSLog(@"Stopped observer '%d-%d'", appPID, winNum);
            break;
        }
    }
}
+ (void) stopObservingApp: (NSRunningApplication*) app {
    NSString* appPID = [NSString stringWithFormat: @"%d", app.processIdentifier];
    NSValue* observerValue = observers[appPID];
    if (observerValue) {
        AXObserverRef observer = [observerValue pointerValue];
        CFRunLoopRemoveSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
        [observers removeObjectForKey: appPID];
        NSLog(@"Stopped observing '%@'", app.localizedName);
    } else NSLog(@"err on stop observing");
    
    //remove all window observers
    NSMutableDictionary* observersCopy = [observers mutableCopy]; //since cannot modify while enumerating
    for (NSString* observerKey in observersCopy) {
        if ([observerKey hasPrefix: [appPID stringByAppendingString: @"-"]]) {
            NSString* winNum = [observerKey substringFromIndex: [appPID stringByAppendingString: @"-"].length];
            [self stopObservingWindow: app.processIdentifier : winNum.intValue];
        }
    }
}
/* todo: find when should call this... */
+ (void) updateSpaces {    /* workaround: when Preferences > Mission Control > "Displays have separate Spaces" is unchecked,
                            switching between displays doesn't trigger .activeSpaceDidChangeNotification; we get the latest manually */
    [Spaces refreshCurrentSpaceId];
    for (Window* win in windows) [win updatesWindowSpace];
}
+ (void) appLaunched: (NSNotification*) note {
    NSRunningApplication* app = (NSRunningApplication*)note.userInfo[@"NSWorkspaceApplicationKey"];
    AXUIElementRef appel = AXUIElementCreateApplication(app.processIdentifier);
    AXUIElementRef focusedWindow = [[helperLib elementDict: appel : @{@"focusedWindow": (id)kAXFocusedWindowAttribute}][@"focusedWindow"] pointerValue];
    CGWindowID windowID;
    _AXUIElementGetWindow(focusedWindow, &windowID);
    focusedPID = app.processIdentifier;
    focusedWindowID = windowID;
    CFArrayRef beforeWindows = CFArrayCreateCopy(kCFAllocatorDefault, visibleWindows);
    setTimeout(^{onLaunchTrackFrontmostWindow(beforeWindows, app);}, 2000); //some launch really slow
    [self observeApp: (NSRunningApplication*)note.userInfo[@"NSWorkspaceApplicationKey"]];
}
+ (void) appTerminated: (NSNotification*) note {
    NSRunningApplication* app = (NSRunningApplication*)note.userInfo[@"NSWorkspaceApplicationKey"];
    [self stopObservingApp: app];
    [closedWindows removeObjectForKey: [NSString stringWithFormat: @"%d", app.processIdentifier]];
}
+ (void) spaceChanged: (NSNotification*) note {
    activationT = 100;
    //todo: iterate over appel (axuiapp element) and get the axwindows, add window observers
    // create observers for running apps
    for (NSRunningApplication* app in [[NSWorkspace sharedWorkspace] runningApplications]) [self observeApp: app];
    [Spaces refreshAllIdsAndIndexes];
    [Spaces updateCurrentSpace];

    for (Window* win in windows) [win updatesWindowSpace];
}
@end
