//
//  gesture.h
//  screenhook
//
//  Created by Steven G on 5/13/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface GestureManager : NSObject {
    NSMutableArray<NSSet<NSTouch*>*>* gesture; // array of NSSet<NSTouch*>* touches
    int touchCount;
    NSString* swipeDirection;
}
- (void) updateTouches: (NSSet<NSTouch*>*) touches : (CGEventRef) event : (CGEventType) type;
- (void) recognizeGesture: (CGEventRef) event : (CGEventType) type;
- (void) endRecognition;
- (void) preProcessTouches;
@end

NS_ASSUME_NONNULL_END
