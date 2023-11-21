//
//  Application.h
//  screenhook
//
//  Created by Steven G on 11/20/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface Application : NSObject {
    @public
    NSRunningApplication* app;
    pid_t pid;
    AXUIElementRef el;
    AXObserverRef observer;
    NSString* name;
    BOOL isPWA;
    NSString* bid;
    NSURL* bundleURL;
    NSURL* executableURL;
    NSDate* launchDate;
}
- (void) destroy;
+ (instancetype) init: (NSRunningApplication*) runningApp;
+ (instancetype) init: (NSRunningApplication*) runningApp : (AXObserverRef) observer;
- (void) setObserver: (AXObserverRef) observer;
@end

NS_ASSUME_NONNULL_END
