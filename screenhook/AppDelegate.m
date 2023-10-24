//
//  AppDelegate.m
//  screenhook
//
//  Created by Steven G on 10/18/23.
//

#import "AppDelegate.h"
#import "src/helperLib.h"

AXUIElementRef systemWideEl = nil;

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@end
@implementation AppDelegate
- (IBAction)openPrefs:(id)sender {[app openPrefs];}
- (IBAction)checkForUpdates:(id)sender {
    app->isSparkleUpdaterOpen = YES;
    [[self updaterController] checkForUpdates: nil];
}
- (IBAction)quit:(id)sender {[NSApp terminate:nil];}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _updaterController = [[SPUStandardUpdaterController alloc] initWithStartingUpdater: YES updaterDelegate: nil userDriverDelegate: nil];
    [helperLib setSystemWideEl: (systemWideEl = AXUIElementCreateSystemWide())];
    [helperLib listenScreens];
    [helperLib processScreens];
    app = [App init: _window : iconMenu : systemWideEl];
}
@end
