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
BOOL initialDiscoveryFinished = NO;
NSArray* AppObserverNotifications;
NSArray* WindowObserverNotifications;
NSMutableArray<Window*>* windows;
NSMutableArray<Application*>* apps;

Application* addNewApp(NSRunningApplication* runningApp) { //add to apps, return it
    Application* ret = [Application init: runningApp];
    [apps addObject: ret];
    return ret;
}

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
            int layer = [winDict[(id)kCGWindowLayer] intValue];
            if (layer != 20 && layer != 500) specialWinCount++; //windows with ownerName=Dock, if owner="Dock" && kCGWindowName != "Dock" => special dock window (exposé / mission control / desktop exposé)....        layer 20 is the dock window titled "Dock" (it doesn't exist w/ autohidden dock until you put mouse over area that reveal it, so just ignore it)         //todo: distinguish desktop exposé           ...    layer 50 window = only exists when dragging anything from the dock (files, dock icons, etc.)
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

void onLaunchTrackFrontmostWindow(CFArrayRef beforeWindows, Application* app) {
    BOOL foundNew = NO;
    //add window observers
    NSArray* wins = [helperLib elementDict: app->el : @{@"windows" : (id)kAXWindowsAttribute}][@"windows"];
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
    if (focusedPID == app->pid) {
        AXUIElementRef focusedWindow = [[helperLib elementDict: app->el : @{@"focusedWindow": (id)kAXFocusedWindowAttribute}][@"focusedWindow"] pointerValue];
        CGWindowID windowID;
        _AXUIElementGetWindow(focusedWindow, &windowID);
        focusedWindowID = windowID;
    }
}

static void axObserverCallback(AXObserverRef observer, AXUIElementRef elementRef, CFStringRef notification, void *refcon) {[WindowManager appObserverCallback: observer : elementRef : notification : refcon];}
static void axWindowObserverCallback(AXObserverRef observer, AXUIElementRef elementRef, CFStringRef notification, void *refcon) {[WindowManager windowObserverCallback: observer : elementRef : notification : refcon];}
@implementation WindowManager
+ (void) init: (void(^)(void)) cb {
    windows = [NSMutableArray array];
    apps = [NSMutableArray array];
    /* activationPolicy & other copied from command-tab (trackfrontapp)
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackFrontApp:) name:NSApplicationDidBecomeActiveNotification object:NSApp];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackFrontApp:) name:NSApplicationDidResignActiveNotification object:NSApp];
     [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(trackFrontApp:) name:@"com.apple.HIToolbox.menuBarShownNotification" object:nil]; */
    AppObserverNotifications = @[(id)kAXApplicationActivatedNotification, (id)kAXMainWindowChangedNotification, (id)kAXFocusedWindowChangedNotification, (id)kAXWindowCreatedNotification, (id)kAXApplicationHiddenNotification, (id)kAXApplicationShownNotification];
    WindowObserverNotifications = @[(id)kAXUIElementDestroyedNotification, (id)kAXTitleChangedNotification, (id)kAXWindowMiniaturizedNotification, (id)kAXWindowDeminiaturizedNotification, (id)kAXWindowResizedNotification, (id)kAXWindowMovedNotification];
    loadVisibleWindows();
    [self initialDiscovery: ^{
        for (Window* win in windows) [win updatesWindowSpace]; //initial discovery sets all win's space info to active space, update to truly finish
        initialDiscoveryFinished = YES;
        cb();
    }];
}
+ (NSArray<Window*>*) windows {return windows;}
+ (Application*) appWithBID: (NSString*) bid {for (Application* app in apps) {if ([app->bid isEqual: bid]) return app;}return nil;}
+ (int) exposeType {return exposeType;}
+ (int) exposeTick {
//    NSLog(@"exposeTick %d", getExposeType());
    return getExposeType();
}

+ (void) initialDiscovery: (void(^)(void)) cb {
    addNewApp([helperLib appWithBID: @"com.apple.dock"]); //we add dock manually since [helperLib isBackgroundApp: ] is true for it
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
            //use hide hack to thoroughly observe apps (except finder), then do the hide trick again on just finder
            NSArray<NSRunningApplication*>* runningApps = NSWorkspace.sharedWorkspace.runningApplications;
            NSMutableArray<NSRunningApplication*>* actualApps = [NSMutableArray array];
            NSMutableArray<NSRunningApplication*>* dockApps = [NSMutableArray array];
            for (NSRunningApplication* app in runningApps) if (![helperLib isBackgroundApp: app]) [actualApps addObject: app];
            for (NSRunningApplication* app in runningApps) if (app.activationPolicy == NSApplicationActivationPolicyRegular) [dockApps addObject: app];
            NSMutableArray<NSRunningApplication*>* unobservedDockApps = [NSMutableArray arrayWithArray: [dockApps copy]];
            
            for (int i = (int)actualApps.count-1; i > -1; i--) {
                NSRunningApplication* app = actualApps[i];
                if (app.isHidden) {
                    [self observeApp: addNewApp(app)]; //we don't have to worry about these apps anymore
                    [actualApps removeObject: app];
                    [unobservedDockApps removeObject: app];
                }
            }
            
            void (^observeOtherApps)(void) = ^{
                for (NSRunningApplication* app in actualApps) {
                    [app hide];
                    setTimeout(^{
                        [self observeApp: addNewApp(app)];
                        [app unhide];
                    }, 333);
                }
                setTimeout(^{cb();}, 334);
            };
            
            //observe dock apps
            if (unobservedDockApps.count == 0) { /*all dock apps were already hidden */
                observeOtherApps();
            } else if (unobservedDockApps.count == 1) { //only 1 app showing => //we cannot hide it without unhiding another app first (or else a random app will unhide)
                if (dockApps.count == 1) { //the only running app is finder (no other app to unhide => add a screenhook window, then hide finder)
                    //add screenhook window
                    //hide finder
                    //observe finder
                    //unhide finder
                    //observeOtherApps();
                } else {
                    if (dockApps.count == 2) { //there is exactly 1 (hidden) app to unhide, hide the app, observe it, then re-hide the other app
                        //...
                        //observeOtherApps();
                    } else if (dockApps.count >= 3) {
                        //... can we re-use observeFrontmost block/loop???
                        //observeOtherApps();
                    }
                }
            } else if (unobservedDockApps.count >= 2) { //at least 2 visible apps, means we can hide/unhide any other app 1 by 1
                [NSApp hide: nil];
                //hide frontmost app
                //observe frontmost app
                //unhide frontmost app
                NSMutableArray<NSRunningApplication*>* hideOrder = [NSMutableArray array];
                __block void (^observeFrontmost)(void);
                void (^finishedObservingDockApps)(void) = ^{
                    for (int i = (int)hideOrder.count - 1; i > -1; i--) {
                        setTimeout(^{
                            [hideOrder[i] unhide];
                            [hideOrder[i] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
                        }, 70*((int)hideOrder.count - 1 - i));
                    }
                    observeOtherApps();
                };
                observeFrontmost = ^{
                    NSRunningApplication* frontmost = NSWorkspace.sharedWorkspace.frontmostApplication;
                    if (unobservedDockApps.count == 1) [hideOrder.lastObject unhide];
                    [frontmost hide];
                    setTimeout(^{
                        [self observeApp: addNewApp(frontmost)]; //we don't have to worry about this app anymore
                        [actualApps removeObject: frontmost];
                        [unobservedDockApps removeObject: frontmost];
                        if (unobservedDockApps.count) observeFrontmost();
                        else finishedObservingDockApps();
                    }, 70);
                    if (frontmost.activationPolicy == NSApplicationActivationPolicyRegular) [hideOrder addObject: frontmost]; //unhiding an accessory app not possible w/o making window the key window, so we ignore
                };
                observeFrontmost();
            }
        }
    }
}
+ (void) windowObserverCallback: (AXObserverRef) observer : (AXUIElementRef) el : (CFStringRef) notification : (void*) refcon {
    NSString* type = (__bridge NSString *)notification;
    int appPID = [[helperLib elementDict: el : @{@"pid": (id)kAXPIDAttribute}][@"pid"] intValue];
//    NSLog(@"observe window notification - %@", type);
    if ([type isEqual: @"AXUIElementDestroyed"]) { // window closed
        Window* win;for (win in windows) if (CFEqual(el, win->el)) break; //find destroyed window by matching destroyed element
        NSLog(@"closed %@ - '%@'", win->app->name, win->title);
        [self stopObservingWindow: win];
        
        NSRunningApplication* front = [[NSWorkspace sharedWorkspace] frontmostApplication];
        Application* app;for (app in apps) if (app->pid == front.processIdentifier) break;
        AXUIElementRef focusedWindow = [[helperLib elementDict: app->el : @{@"focusedWindow": (id)kAXFocusedWindowAttribute}][@"focusedWindow"] pointerValue];
        CGWindowID windowID;
        _AXUIElementGetWindow(focusedWindow, &windowID);
//        for (win in windows) if (win->winNum == windowID) break; //get new focused Window
        focusedPID = app->pid;
        focusedWindowID = windowID;
    } else {
        loadVisibleWindows();
        CGWindowID windowID;
        _AXUIElementGetWindow(el, &windowID);
        if (windowID) {
            focusedWindowID = windowID;
            focusedPID = appPID;
        } else {
            NSLog(@"WINDOW NOT GIVING ITS ID..... pid %d note %@", appPID, notification);
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
+ (void) appObserverCallback: (AXObserverRef) observer : (AXUIElementRef) el : (CFStringRef) note : (void*) refcon {
    if (!initialDiscoveryFinished) return; // on hide, (Application*) app may not exist for new frontmost app
    NSString* type = (__bridge NSString *)note;
    pid_t frontPID = [[helperLib elementDict: el : @{@"pid": (id)kAXPIDAttribute}][@"pid"] intValue];
    if ([type isEqual: @"AXApplicationHidden"]) frontPID = [[NSWorkspace sharedWorkspace]frontmostApplication].processIdentifier;
    Application* app;for (app in apps) if (app->pid == frontPID) break;
    if ([type isEqual: @"AXApplicationActivated"] || [type isEqual: @"AXApplicationHidden"]) {
        AXUIElementRef focusedWindow = [[helperLib elementDict: app->el : @{@"focusedWindow": (id)kAXFocusedWindowAttribute}][@"focusedWindow"] pointerValue];
        CGWindowID windowID;
        _AXUIElementGetWindow(focusedWindow, &windowID);
        focusedWindowID = windowID;
        focusedPID = app->pid;
    } else {
        loadVisibleWindows();
        CGWindowID windowID;
        _AXUIElementGetWindow(el, &windowID);
        if (windowID) {
            focusedWindowID = windowID;
            focusedPID = app->pid;
        }
        if ([type isEqual: @"AXWindowCreated"]) [self observeWindow: el : app : windowID];
    }
}
+ (void) observeWindow: (AXUIElementRef) axWindow : (Application*) app : (CGWindowID) winNum {
    for (Window* win in windows) if (win->winNum == winNum) return /*NSLog(@"observer already exists for window %d", winNum)*/;
    if (winNum == 0) return; //finder desktop window (or windows created before login?) cannot be observed / not a "real" window
    // Create an observer
    AXObserverRef observer;
    AXError err = AXObserverCreate(app->pid, axWindowObserverCallback, &observer);
    if (err) return NSLog(@"err1 %@ - %d", [helperLib appWithPID: app->pid].localizedName, err);
    // Add notifications to the observer
    for (NSString* notification in WindowObserverNotifications) {
        err = AXObserverAddNotification(observer, axWindow, (__bridge CFStringRef)notification, (__bridge void * _Nullable)(self));
        if (err) {NSLog(@"Error adding %@ notification for '%@' - %d", notification, app->name, err);}
    }
    // Register the observer with the run loop
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
    [windows addObject: [Window init: app : axWindow : winNum : observer]];
    NSLog(@"window observers added for %@ - '%@'", windows.lastObject->app->name, windows.lastObject->title);
}
+ (void) observeApp: (Application*) app {
    if (app->app.activationPolicy == NSApplicationActivationPolicyProhibited || [helperLib isBackgroundApp: app->app]) return /* NSLog(@"skip %@", app.localizedName) */;
    if (!app->observer) {
        AXObserverRef observer;
        AXError err = AXObserverCreate(app->pid, axObserverCallback, &observer);
        if (err) return NSLog(@"err1 %@ - %d", app->name, err);
        for (NSString* notification in AppObserverNotifications) {
            err = AXObserverAddNotification(observer, app->el, (__bridge CFStringRef)notification, (__bridge void * _Nullable)(self));
            if (err) {NSLog(@"Error adding %@ notification for '%@' - %d", notification, app->name, err);}
        }
        CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
        NSLog(@"Observers created for '%@'", app->name);
        [app setObserver: observer];
    }
    
    //add window observers
    NSArray* windows = [helperLib elementDict: app->el : @{@"windows" : (id)kAXWindowsAttribute}][@"windows"];
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
+ (void) stopObservingWindow: (Window*) window {
    if (!window) NSLog(@"??? NO WIN ??? (this shouldn't happen)");
    for (int i = (int)windows.count - 1; i > -1; i--) {
        Window* win = windows[i];
        if (win->winNum == window->winNum) {
            if (!win->observer) {
                NSLog(@"\nWINDOW W/O OBSERVER - APP: %@ - '%@'\n", window->app->name, window->title);
                [windows removeObjectAtIndex: i];
                break;
            }
            CFRunLoopRemoveSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(win->observer), kCFRunLoopDefaultMode);
            [win destroy];
            [windows removeObjectAtIndex: i];
            NSLog(@"Stopped observing window %@ - '%@'", window->app->name, window->title);
            break;
        }
    }
}
+ (void) stopObservingApp: (Application*) app {
    if (app->observer) {
        CFRunLoopRemoveSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(app->observer), kCFRunLoopDefaultMode);
        [app destroy];
    } else NSLog(@"err on stop observing");
    
    //remove all window observers
    for (int i = (int)windows.count-1; i > -1; i--) {
        Window* win = windows[i];
        if (win->app->pid == app->pid) [self stopObservingWindow: win];
    }
    [apps removeObject: app];
    NSLog(@"stopped observing app %@", app->name);
}
/* todo: find when should call this... */
+ (void) updateSpaces {    /* workaround: when Preferences > Mission Control > "Displays have separate Spaces" is unchecked,
                            switching between displays doesn't trigger .activeSpaceDidChangeNotification; we get the latest manually */
    [Spaces refreshCurrentSpaceId];
    for (Window* win in windows) [win updatesWindowSpace];
}
+ (void) appLaunched: (NSRunningApplication*) runningApp {
    if (![helperLib isBackgroundApp: runningApp]) {
        Application* app = addNewApp(runningApp);
        //front app/window tracking
        AXUIElementRef focusedWindow = [[helperLib elementDict: app->el : @{@"focusedWindow": (id)kAXFocusedWindowAttribute}][@"focusedWindow"] pointerValue];
        CGWindowID windowID;
        _AXUIElementGetWindow(focusedWindow, &windowID);
        focusedPID = app->pid;
        focusedWindowID = windowID;
        CFArrayRef beforeWindows = CFArrayCreateCopy(kCFAllocatorDefault, visibleWindows);
        setTimeout(^{onLaunchTrackFrontmostWindow(beforeWindows, app);}, 2000); //some launch really slow
        
        [self observeApp: app];
    }
}
+ (void) appTerminated: (NSRunningApplication*) runningApp {
    if (![helperLib isBackgroundApp: runningApp]) {
        Application* app; for (app in apps) if (app->pid == runningApp.processIdentifier) break;
        [self stopObservingApp: app];
    }
}
+ (void) spaceChanged: (NSNotification*) note {
    activationT = 100;
    //todo: iterate over appel (axuiapp element) and get the axwindows, add window observers
    // create observers for running apps
    for (Application* app in apps) [self observeApp: app];
    [Spaces refreshAllIdsAndIndexes];
    [Spaces updateCurrentSpace];

    for (Window* win in windows) [win updatesWindowSpace];
}
@end
