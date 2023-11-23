//
//  gesture.h
//  screenhook
//
//  Created by Steven G on 11/22/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface GestureManager : NSObject {
    NSMutableArray<NSSet<NSTouch*>*>* gesture; // array of NSSet<NSTouch*>* touches
    int touchCount;
    @public BOOL isClickSwipe;
}
- (instancetype) init;
- (void) recognizeMultiFingerTap;
- (void) updateTouches: (NSSet<NSTouch*>*) touches : (CGEventRef) event : (CGEventType) type;
- (void) recognizeGesture: (CGEventRef) event : (CGEventType) type;
- (void) endRecognition;
- (void) detectSwipeGesture;
- (void) resetTriggeredGestures;
- (void) setIsClickSwipe;
- (CGEventTapCallBack) allHandler: (CGEventTapProxy) proxy : (CGEventType) type : (CGEventRef) event : (void*) refcon;
+ (void) on: (NSString*) ev : (void (^)(BOOL granted))handler;
- (void) on: (NSString*) ev : (void (^)(BOOL granted))handler;
@end

NS_ASSUME_NONNULL_END
