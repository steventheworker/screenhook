//
//  SpotlightSearch.m
//  screenhook
//
//  Created by Steven G on 11/22/23.
//

#import "SpotlightSearch.h"
#import "../globals.h"
#import "../helperLib.h"
#import "../WindowManager.h"

BOOL downStarted = NO;
BOOL wasSpotlightOpenOnDown = NO;
int spotlightType = 0; //spotlight = 1, alfred = 2, ...

@implementation SpotlightSearch
+ (BOOL) mousedown: (CGPoint) pos : (AXUIElementRef) el : (NSDictionary*) elDict {
    if (spotlightType == 0) spotlightType = [WindowManager appWithBID: @"com.runningwithcrayons.Alfred"] ? 2 : 1;
    if ([elDict[@"pid"] intValue] != [WindowManager appWithBID: @"com.apple.dock"]->pid) return YES;
    downStarted = YES;
    wasSpotlightOpenOnDown = ![[helperLib applescript: [NSString stringWithFormat: @"tell application \"System Events\" to tell process \"%@\" to count of windows", spotlightType == 2 ? @"Alfred" : @"Spotlight"]] isEqual:@"0"];
    if (wasSpotlightOpenOnDown) {
        if (spotlightType == 2) [helperLib applescript: @"tell application \"System Events\" to key code 53"];
        else [helperLib applescript: @"tell application \"System Events\" to keystroke \" \" using {command down}"];
    }
    return NO;
}
+ (BOOL) mouseup: (CGPoint) pos : (AXUIElementRef) el : (NSDictionary*) elDict {
    if (!downStarted) return YES;
    downStarted = NO;
    if ([elDict[@"title"] isEqual: @"Spotlight Search"] && !wasSpotlightOpenOnDown) {
        setTimeout(^{
            if (spotlightType == 2) [helperLib applescript: @"do shell script \"osascript -e 'tell application \\\"Alfred 5\\\" to search' &> /dev/null & echo $!\""];
            else [helperLib applescript: @"tell application \"System Events\" to keystroke \" \" using {command down}"];
        }, spotlightType == 2 ? 100 : 200); // system events is slower than app telling Alfred
    }
    return NO;
}
@end
