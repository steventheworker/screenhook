//
//  AppDelegate.h
//  screenhook
//
//  Created by Steven G on 9/18/21.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    @public AXUIElementRef          _systemWideAccessibilityObject;
}
+ (void) bindScreens;

@end

