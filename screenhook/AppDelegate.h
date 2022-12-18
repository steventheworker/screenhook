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
    NSStatusItem *statusItem;
    __weak IBOutlet NSMenu *iconMenu;
    __weak IBOutlet NSView *MainMenu;
    __weak IBOutlet NSTextField *BTTState;
}
/*
   Event handlers
*/
- (void) mousedown: (CGEventRef) e : (CGEventType) etype;
- (void) mouseup: (CGEventRef) e : (CGEventType) etype;
- (void) bindScreens;
- (void) measureScreens;
/*
    Menu Bindings / UI handlers
*/
- (IBAction) preferences:(id)sender;
/*
    helpers
*/
- (void) closePreferences;
@end
