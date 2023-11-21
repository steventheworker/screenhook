//
//  Window.m
//  screenhook
//
//  Created by Steven G on 11/17/23.
//

#import "Window.h"
#import "helperLib.h"
#import "Spaces.h"

extern AXError CGSCopyWindowProperty(int cid, CGWindowID wid, CFStringRef prop, void* input); // private api fallback

int globalCreationCounter = 0;
@implementation Window
- (void) destroy {
    CFRelease(self->observer);
    CFRelease(self->el);
    self->observer = nil;
    self->el = nil;
}
+ (instancetype) init : (Application*) app : (AXUIElementRef) el : (CGWindowID) winNum : (AXObserverRef) observer {
    /*var lastFocusOrder = Int.zero */
    /* ^^^^ updated on focusedWindowChanged and applicationActivated*/
    CFRetain(el);
    CFRetain(observer);

    //args
    Window* win = [[self alloc] init];
    win->observer = observer;
    win->el = el;
    win->app = app;
    win->winNum = winNum;

    //derived info
    NSDictionary* info = [helperLib elementDict: el : @{
        @"isFullscreen": (id)kAXFullscreenAttribute,
        @"isMinimized": (id)kAXMinimizedAttribute,
        @"pos": (id)kAXPositionAttribute,
        @"size": (id)kAXSizeAttribute,
    }];
    win->title = nil;
    if (!win->title.length) {
        NSString* val;
        CGSCopyWindowProperty([Spaces CGSMainConnectID], winNum, CFSTR("kCGSWindowTitle"), &val);
        win->title = val.length ? val : app->name; // fallback to app.localizedName
    }
    win->isFullscreen = [info[@"isFullscreen"] boolValue];
    win->isMinimized = [info[@"isMinimized"] boolValue];
    win->pos = NSMakePoint([info[@"pos"][@"x"] floatValue], [info[@"pos"][@"y"] floatValue]);
    win->size = NSMakeSize([info[@"size"][@"w"] floatValue], [info[@"size"][@"h"] floatValue]);

    win->creationOrder = ++globalCreationCounter;
    win->spaceId = [Spaces currentSpaceId];
    win->spaceIndex = [Spaces currentSpaceIndex];
    win->isOnAllSpaces = false;
    return win;
}
- (void) updatesWindowSpace {
    // macOS bug: if you tab a window, then move the tab group to another space, other tabs from the tab group will stay on the current space
    // you can use the Dock to focus one of the other tabs and it will teleport that tab in the current space, proving that it's a macOS bug
    // note: for some reason, it behaves differently if you minimize the tab group after moving it to another space
    NSArray* spaceIds = CGSCopySpacesForWindows([Spaces CGSMainConnectID], CGSSpaceMaskAll, @[@(self->winNum)]);
    if (spaceIds.count == 1) {
        self->spaceId = [spaceIds[0] intValue];
        self->spaceIndex = [Spaces indexWithID: self->spaceId];
        self->isOnAllSpaces = false;
    } else if (spaceIds.count > 1) {
        spaceId = [Spaces currentSpaceId];
        spaceIndex = [Spaces currentSpaceIndex];
        self->isOnAllSpaces = true;
    }
}

/*
- func isEqualRobust(_ otherWindowAxUiElement: AXUIElement, _ otherWindowWid: CGWindowID?) -> Bool {
    // the window can be deallocated by the OS, in which case its `CGWindowID` will be `-1`
    // we check for equality both on the AXUIElement, and the CGWindowID, in order to catch all scenarios
    return otherWindowAxUiElement == axUiElement || (cgWindowId != nil && Int(cgWindowId!) != -1 && otherWindowWid == cgWindowId)
}

- func isOnScreen(_ screen: NSScreen) -> Bool {
        if let screenUuid = screen.uuid(), let screenSpaces = Spaces.screenSpacesMap[screenUuid] {
            return screenSpaces.contains { $0 == spaceId }
        }
}

*/
@end
