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
    @public
    NSMutableArray<NSSet<NSTouch*>*>* gesture; // array of NSSet<NSTouch*>* touches
    int touchCount;
    BOOL isClickSwipe;
    NSMutableDictionary<NSString*, NSMutableArray<BOOL (^)(GestureManager*)>*>* callbackMap;
    
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
+ (void) on: (NSString*) ev : (BOOL (^)(GestureManager* gm)) handler;
- (void) on: (NSString*) ev : (BOOL (^)(GestureManager* gm)) handler;
@end

NS_ASSUME_NONNULL_END
