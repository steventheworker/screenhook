//
//  spaceKeyboardShortcuts.h
//  screenhook
//
//  Created by Steven G on 11/10/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface spaceKeyboardShortcuts : NSObject
+ (void) init;
+ (void) keyCode: (int) keyCode;
+ (void) spaceChanged: (NSNotification*) note;
@end

NS_ASSUME_NONNULL_END
