//
//  AppDelegate.h
//  DockAltTab
//
//  Created by Steven G on 9/18/21.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    @public AXUIElementRef   _systemWideAccessibilityObject;
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
    BOOL                   dockautohide;
    NSDictionary*         runningApps;

    //UI
}
- (void) mousedown: (CGEventRef) e : (CGEventType) etype;
- (void) mouseup: (CGEventRef) e : (CGEventType) etype;
- (void) bindScreens;
- (void) measureScreens;
@end
