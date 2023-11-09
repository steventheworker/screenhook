//
//  missionControlSpaceLabels.h
//  screenhook
//
//  Created by Steven G on 11/8/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface missionControlSpaceLabels : NSObject
+ (void) init;
+ (void) tick: (int) exposeType;
+ (void) render;
+ (void) labelClicked: (AXUIElementRef) el;
@end

NS_ASSUME_NONNULL_END
