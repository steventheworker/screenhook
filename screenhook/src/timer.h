//
//  timer.h
//  Dock Exposé
//
//  Created by Steven G on 4/4/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface timer : NSObject {
    @public NSTimer* timerRef;

}
- (void) initializer;
@end

NS_ASSUME_NONNULL_END
