//
//  timer.h
//  Dock Exposé
//
//  Created by Steven G on 4/4/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface timer : NSObject {
    @public NSTimer* timerRef;

}
- (void) initializer;
+ (void) mousedown: (CGEventRef) e : (CGEventType) etype;
+ (void) mouseup: (CGEventRef) e : (CGEventType) etype;
+ (void) trackFrontApp: (NSNotification*) notification;
+ (void) updateFFSidebarShowing: (BOOL) val;
@end

NS_ASSUME_NONNULL_END
