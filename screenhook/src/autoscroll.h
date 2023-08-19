//
//  autoscroll.h
//  screenhook
//
//  Created by Steven G on 8/18/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface autoscroll : NSObject {}
+ (BOOL) mousedown: (CGEventRef) e : (CGEventType) etype;
+ (BOOL) mouseup: (CGEventRef) e : (CGEventType) etype;
@end

NS_ASSUME_NONNULL_END