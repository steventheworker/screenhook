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
@property (nonatomic, readwrite) NSString* dockPos;
@property (nonatomic, readwrite) BOOL dockAutohide;
+ (void) init;
+ (void) tick;
+ (void) startTicking;

/* events */
+ (BOOL) processEvent: (CGEventTapProxy) proxy : (CGEventType) type : (CGEventRef) event : (void*) refcon : (NSString*) eventString;
+ (void) appLaunched: (NSNotification*) note;
+ (void) appTerminated: (NSNotification*) note;
+ (void) spaceChanged: (NSNotification*) note;
+ (void) spaceadded: (int) spaceIndex;
+ (void) spaceremoved: (int) spaceIndex;
+ (void) spacemoved: (int) monitorStartIndex : (NSArray*) newIndexing;
+ (void) processScreens: (CGDirectDisplayID) display : (CGDisplayChangeSummaryFlags) flags : (void*) userInfo;
@end

NS_ASSUME_NONNULL_END
