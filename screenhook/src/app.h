//
//  app.h
//  screenhook
//
//  Created by Steven G on x/x/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface app : NSObject
+ (void) init;
+ (BOOL) isSpotlightOpen : (BOOL) isAlfred;
+ (void) twoFingerSwipeFromLeftEdge;
+ (void) startListening;
+ (void) stopListening;
@end
NS_ASSUME_NONNULL_END
