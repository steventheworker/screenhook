//
//  desktopPeak.h
//  screenhook
//
//  Created by Steven G on 12/1/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface desktopPeak : NSObject
+ (void) init;
+ (BOOL) mousedown: (AXUIElementRef) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos;
+ (BOOL) mouseup: (AXUIElementRef) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos;
+ (void) mousemove: (CGPoint) cursorPos : (BOOL) isDragging;
@end

NS_ASSUME_NONNULL_END
