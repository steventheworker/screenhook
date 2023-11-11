//
//  spaceKeyboardShortcuts.m
//  screenhook
//
//  Created by Steven G on 11/10/23.
//

#import "spaceKeyboardShortcuts.h"
#import "../Spaces.h"

extern void CGSManagedDisplaySetCurrentSpace(const /* CGSConnectionID */ int cid, /* CGSManagedDisplay */ CFStringRef display, /* CGSSpace */ uint64_t space);
extern /* CGSManagedDisplay */ CFStringRef kCGSPackagesMainDisplayIdentifier;
@implementation spaceKeyboardShortcuts
+ (void) init {
    //onlaunch put invisible window on space
}
+ (void) keyCode: (int) keyCode {
    NSArray* spaces = [Spaces spaces];
    NSDictionary* digits = @{@18: @1, @19: @2, @20: @3, @21: @4, @23: @5, @22: @6, @26: @7, @28: @8, @25: @9};
    int digit = [digits[@(keyCode)] intValue];
    int targetSpace;
    switch (digit) { //so 1 = 0% of spaces (Space 1), 2-8 = (Space at index x/9 % of the way), 9 = 100% desktops (last Desktop)
        case 1:
            targetSpace = 1;
            break;
        case 9:
            targetSpace = (int) spaces.count;
            break;
        default:
            targetSpace = roundf((float)digit/9 * (float)spaces.count);
            break;
    }
    int targetSpaceIndex = targetSpace - 1;
    
    //if space does not yet have invisible window to activate, see if window on space exists you have axref for and activate that
        //else fallback to trigger keyboard shortcuts (control+leftarrow/rightarrow)
    
    //i thought this would let me go directly to space, but it just brings target space's windows into current space in a glitchy way
    CGSManagedDisplaySetCurrentSpace([Spaces CGSMainConnectID], kCGSPackagesMainDisplayIdentifier, (uint64_t) [spaces[targetSpaceIndex][0] intValue]);
}
+ (void) spaceChanged: (NSNotification*) note {
    //onspacechange put invisible window on space (if DNE)
}
@end
