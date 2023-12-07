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
+ (void) clearViews;
+ (void) addOverlayWindows;
+ (void) labelClicked: (AXUIElementRef) el;
+ (void) setLabel: (int) spaceindex : (NSString*) newLabel;
+ (void) reshow;
+ (BOOL) mousedown: (AXUIElementRef) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos;
+ (void) mouseup;
+ (void) spaceChanged: (NSNotification*) note;
+ (void) processScreens: (NSScreen*) screen : (CGDisplayChangeSummaryFlags) flags : (NSString*) uuid;
@end

NS_ASSUME_NONNULL_END
