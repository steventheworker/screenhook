//
//  screenhook.h
//  screenhook
//
//  Created by Steven G on 11/7/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface screenhook : NSObject
+ (void) init;
+ (void) tick;
+ (void) startTicking;
+ (BOOL) processEvent: (CGEventTapProxy) proxy : (CGEventType) type : (CGEventRef) event : (void*) refcon : (NSString*) eventString;
@end

NS_ASSUME_NONNULL_END
