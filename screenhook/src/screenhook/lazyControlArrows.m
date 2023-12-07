//
//  lazyControlArrows.m
//  screenhook
//
//  Created by Steven G on 12/1/23.
//

#import "lazyControlArrows.h"
#import "../helperLib.h"
#import "spaceKeyboardShortcuts.h"

const float ARROWREPEAT_T = 0.666 * 2; //seconds, how long it takes for fast-switching animations to stop
const float ARROWSEND_T = 0.333 / 4; //seconds, how long to send the arrow
NSDate* lastArrowExecT;
NSDate* lastArrowSentT;

@implementation lazyControlArrows
+ (void) init {
    lastArrowExecT = [NSDate date];
    lastArrowSentT = [NSDate date];
}
+ (BOOL) keyCode: (int) keyCode : (NSString*) eventString : (NSDictionary*) modifiers {
    //ctrl+left-arrow
    if ([eventString isEqual: @"keydown"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 123) {
        NSDate* t0 = lastArrowExecT;
        lastArrowExecT = NSDate.date;
        if ([lastArrowExecT timeIntervalSinceDate: t0] <= ARROWREPEAT_T) {
            if ([lastArrowExecT timeIntervalSinceDate: lastArrowSentT] >= ARROWSEND_T) {
                [helperLib sendKey: 123];
                lastArrowSentT = lastArrowExecT;
            }
            return YES;
        }
        [spaceKeyboardShortcuts prevSpace];
        return NO;
    }
    if ([eventString isEqual: @"keyup"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 123) {
        NSDate* t0 = lastArrowExecT;
        lastArrowExecT = NSDate.date;
        if ([lastArrowExecT timeIntervalSinceDate: t0] <= ARROWREPEAT_T) {
            return YES;
        }
        return NO;
    }
    //ctrl+right-arrow
    if ([eventString isEqual: @"keydown"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 124) {
        NSDate* t0 = lastArrowExecT;
        lastArrowExecT = NSDate.date;
        if ([lastArrowExecT timeIntervalSinceDate: t0] <= ARROWREPEAT_T) {
            if ([lastArrowExecT timeIntervalSinceDate: lastArrowSentT] >= ARROWSEND_T) {
                [helperLib sendKey: 124];
                lastArrowSentT = lastArrowExecT;
            }
            return YES;
        }
        [spaceKeyboardShortcuts nextSpace];
        return NO;
    }
    if ([eventString isEqual: @"keyup"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 124) {
        NSDate* t0 = lastArrowExecT;
        lastArrowExecT = NSDate.date;
        if ([lastArrowExecT timeIntervalSinceDate: t0] <= ARROWREPEAT_T) return YES;
        return NO;
    }
    return YES;
}
@end
