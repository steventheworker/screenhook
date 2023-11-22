//
//  SpotlightSearch.h
//  screenhook
//
//  Created by Steven G on 11/22/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SpotlightSearch : NSObject
+ (BOOL) mousedown: (CGPoint) pos : (AXUIElementRef) el : (NSDictionary*) elDict;
+ (BOOL) mouseup: (CGPoint) pos : (AXUIElementRef) el : (NSDictionary*) elDict;
@end

NS_ASSUME_NONNULL_END
