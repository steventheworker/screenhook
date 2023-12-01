//
//  lazyControlArrows.h
//  screenhook
//
//  Created by Steven G on 12/1/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface lazyControlArrows : NSObject
+ (void) init;
+ (BOOL) keyCode: (int) keyCode : (NSString*) eventString : (NSDictionary*) modifiers;
@end

NS_ASSUME_NONNULL_END
