//
//  AppDelegate.h
//  DockAltTab
//
//  Created by Steven G on 9/18/21.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    //permissions
    @public AXUIElementRef          _systemWideAccessibilityObject;
    
    //system state (non-live / eg. periodically updated)
    @public float           primaryScreenHeight;
    @public float           primaryScreenWidth;
    @public float           extendedOffsetX;
    @public float           extendedOffsetY;
    @public float           extendedOffsetYBottom;
    @public float           extScreenWidth;
    @public float           extScreenHeight;
    @public CGFloat         dockWidth;
    @public CGFloat         dockHeight;
    @public NSString*       dockPos;
    pid_t                  dockPID;
    pid_t                  finderPID;
    pid_t                  AltTabPID;
    BOOL                   unsupportedAltTab;
    BOOL                   autohide;

    //app stuff
    NSTimer*               timer;
    BOOL                   wasShowingContextMenu;
    
    NSDictionary*         runningApps;

    //UI
}
//- (float) timeDiff;
- (void) mousedown: (CGEventRef) e : (CGEventType) etype;
- (void) mouseup: (CGEventRef) e : (CGEventType) etype;
- (void) bindScreens;
@end
