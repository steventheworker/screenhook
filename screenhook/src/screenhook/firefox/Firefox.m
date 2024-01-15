//
//  Firefox.m
//  screenhook
//
//  Created by Steven G on 1/14/24.
//

#import "Firefox.h"
#import "../../WindowManager.h"
#import "../../helperLib.h"
#import "../../globals.h"

@implementation FFs
- (instancetype) init : (pid_t) pid {
    self = [super init];
    self->pid = pid;
    self->reopenOrder = NSMutableArray.array;
    return self;
}
- (void) destroy {
    self->reopenOrder = NSMutableArray.array;
    CFRelease((__bridge CFTypeRef)(self));
}
@end

@implementation FirefoxManager
- (instancetype) init {
    self = [super init];
    self.FFs = NSMutableDictionary.dictionary;
    for (NSRunningApplication* app in NSWorkspace.sharedWorkspace.runningApplications)
        if ([app.localizedName hasPrefix: @"Firefox"]) [self initFF: app.processIdentifier];
    return self;
}
- (void) appTerminated: (pid_t) pid {
    [(FFs*)self.FFs[@(pid)] destroy];
}
- (void) initFF: (pid_t) pid {
    self.FFs[@(pid)] = [[FFs alloc] init: pid];
}
- (BOOL) mousedown: (id) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos {
    BOOL isFF = [self.FFs objectForKey: cursorDict[@"pid"]];
    
    return YES;
}
- (BOOL) mouseup: (id) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos {
    BOOL isFF = [self.FFs objectForKey: cursorDict[@"pid"]];
    
    return YES;
}
- (void) mousemove: (CGPoint) cursorPos : (BOOL) isDragging {
    
}
@end
