//
//  AppDelegate.h
//  screenhook
//
//  Created by Steven G on 10/18/23.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>
#import "src/app.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    @public
    App* app;
    __weak IBOutlet NSMenu *iconMenu;
}
@property SPUStandardUpdaterController* updaterController;
- (IBAction)quit:(id)sender;
@end

