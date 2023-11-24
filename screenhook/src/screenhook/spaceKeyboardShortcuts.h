//
//  spaceKeyboardShortcuts.h
//  screenhook
//
//  Created by Steven G on 11/10/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface spaceKeyboardShortcuts : NSObject
+ (void) init;
+ (BOOL) visitSpace: (int) spaceIndex;
+ (void) prevSpace;
+ (void) nextSpace;
+ (void) keyCode: (int) keyCode;
+ (void) spaceChanged: (NSNotification*) note;
+ (void) spaceadded: (int) spaceIndex;
+ (void) spaceremoved: (int) spaceIndex;
+ (void) spacemoved: (int) monitorStartIndex : (NSArray*) newIndexing;
+ (void) processScreens: (CGDirectDisplayID) display : (CGDisplayChangeSummaryFlags) flags : (void*) userInfo;
@end

NS_ASSUME_NONNULL_END
