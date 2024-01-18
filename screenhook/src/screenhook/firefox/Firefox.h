//
//  Firefox.h
//  screenhook
//
//  Created by Steven G on 1/14/24.
//

#import <Foundation/Foundation.h>
#import "../../Application.h"

NS_ASSUME_NONNULL_BEGIN

@interface FFs : NSObject {
    @public
    NSString* name;
    pid_t pid;
    NSMutableArray* reopenOrder; //todo: cmd-shift-t
}
@end

@interface FirefoxManager : NSObject {
    @public
    BOOL startedMoving;
    CGPoint startPos;
    NSRect startFrame;
    id moveWindow;
    id mousedownEl;
    NSDate* sideberyLongPressT;
}
@property (strong) NSMutableDictionary<NSNumber*, FFs*>* FFs;
- (instancetype) init;
- (void) initFF: (pid_t) pid;
- (void) appTerminated: (pid_t) pid;
- (BOOL) mousedown: (id) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos;
- (BOOL) mouseup: (id) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos;
- (void) mousemove: (CGPoint) cursorPos : (BOOL) isDragging;
- (void) defocusPIP: (Application*) app;
@end

NS_ASSUME_NONNULL_END
