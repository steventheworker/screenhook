//
//  Application.m
//  screenhook
//
//  Created by Steven G on 11/20/23.
//

#import "Application.h"

@implementation Application
- (void) destroy {
    CFRelease(self->observer);
    CFRelease(self->el);
    self->observer = nil;
    self->el = nil;
}
+ (instancetype) init: (NSRunningApplication*) runningApp {
    Application* app = [[self alloc] init];
    app->app = runningApp;
    app->pid = runningApp.processIdentifier; //there can multiple vlc runningApp's (processes), but pid is what uniquely identifies an nsrunningapp
    app->el = AXUIElementCreateApplication(app->pid);
    CFRetain(app->el);
    app->name = runningApp.localizedName;
    app->isPWA = [runningApp.bundleIdentifier hasPrefix: @"com.apple.WebKit"];
    app->bid = runningApp.bundleIdentifier;
    app->bundleURL = runningApp.bundleURL;
    app->executableURL = runningApp.executableURL;
    app->launchDate = runningApp.launchDate;
    return app;
}
+ (instancetype) init: (NSRunningApplication*) runningApp : (AXObserverRef) observer {
    Application* app = [self init: runningApp];
    [app setObserver: observer];
    return app;
}
- (void) setObserver: (AXObserverRef) observer {
    CFRetain(observer);
    self->observer = observer;
}
@end
