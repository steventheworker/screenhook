//
//  Window.h
//  screenhook
//
//  Created by Steven G on 11/17/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "Application.h"

NS_ASSUME_NONNULL_BEGIN

@interface Window : NSObject {
    @public
    id el;
    Application* app;
    CGWindowID winNum;
    AXObserverRef observer;
    
    NSString* title;
    BOOL isFullscreen;
    BOOL isMinimized;
    NSPoint pos;
    NSSize size;

    int creationOrder;
    int spaceId;
    int spaceIndex;
    BOOL isOnAllSpaces;
}
- (void) destroy;
+ (instancetype) init : (Application*) app : (id) el : (CGWindowID) winNum : (AXObserverRef) observer;
- (void) updatesWindowSpace;
@end

NS_ASSUME_NONNULL_END
