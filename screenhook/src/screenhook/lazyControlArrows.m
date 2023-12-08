//
//  lazyControlArrows.m
//  screenhook
//
//  Created by Steven G on 12/1/23.
//

#import "lazyControlArrows.h"
#import "../globals.h"
#import "../helperLib.h"
#import "spaceKeyboardShortcuts.h"
#import "../Spaces.h"

const float SPACESWITCHMODE_T = 0.666 * 2; //seconds, how long it takes for fast-switching animations to stop (at which point using spacewindow's is faster (than sendKey))
const int FASTDESKTOPSWITCH_T = 188; //(ms) to switch again
const int SLOWDESKTOPSWITCH_T = 400; //(ms) to switch with prevSpace/nextSpace
const float ARROWSEND_T = 0.333 / 4; //(sec) how long to send the arrow
int calculatedSpaceIndex = 1; //the spaceindex you started at when calling the shortcuts ± the # sent prev/nextSpace/sendKey

BOOL hasStarted = NO;
enum directions {Forward, Backward};enum switchType {spacewindow, sendKey};
int direction = Forward;
NSDate* runShortcutT;
BOOL propagateOne = NO; //we propagate a single one after doing sendKey (so the space will actually switch)
int perpetuationTime = SLOWDESKTOPSWITCH_T; //wait time for prev/nextSpace
int perpetuationCounter = 0;

@implementation lazyControlArrows
+ (void) init {
    calculatedSpaceIndex = Spaces.currentSpaceIndex;
    runShortcutT = NSDate.date;
}
+ (BOOL) shortcutUp {
    if (propagateOne) {propagateOne = NO;return YES;}
    //end the loop
    hasStarted = NO;
    perpetuationCounter++;
    return NO;
}
+ (BOOL) shortcutDown: (int) keyCode {
    if (propagateOne) {/*propagateOne = NO;*/return YES;}
    if (hasStarted) return NO;
    //start the loop
    hasStarted = YES;
    direction = keyCode == 123;
    [self perpetuate];
    return NO;
}
+ (void) runShortcut: (BOOL) shouldSendKeys {
    if (shouldSendKeys) {
        propagateOne = YES; //pass one Ctrl+Arrow through (ie: don't preventDefault, once)
        [helperLib sendKey: direction == Forward ? 124 : 123];
        perpetuationTime = FASTDESKTOPSWITCH_T;
    } else {
        direction == Forward ? [spaceKeyboardShortcuts nextSpace] : [spaceKeyboardShortcuts prevSpace];
        perpetuationTime = SLOWDESKTOPSWITCH_T;
    }
    runShortcutT = NSDate.date;
    
    if (!shouldSendKeys) { //see if next/prevSpace will go to the first/last space, fix the calculatedSpaceIndex
        CGPoint mouseLoc = [helperLib CGPointFromNSPoint: [NSEvent mouseLocation]];
        NSScreen* mouseScreen = [helperLib screenAtCGPoint: mouseLoc];
        NSArray* screenSpaceIds = [Spaces screenSpacesMap][[Spaces uuidForScreen: mouseScreen]];
        int startIndex = [Spaces indexWithID: [screenSpaceIds.firstObject intValue]];
        if (calculatedSpaceIndex == startIndex && direction == Backward) {
            calculatedSpaceIndex = startIndex + (int)screenSpaceIds.count - 1;
            return;
        }
        if (calculatedSpaceIndex == startIndex + (int)screenSpaceIds.count - 1 && direction == Forward) {
            calculatedSpaceIndex = startIndex;
            return;
        }
    }
    calculatedSpaceIndex += (direction == Forward ? 1 : -1);
}
+ (void) sendKeyOrSpacewindow {
    NSLog(@"calcd %d", calculatedSpaceIndex);
    if ([NSDate.date timeIntervalSinceDate: runShortcutT] >= SPACESWITCHMODE_T) {//space stabel
        [Spaces refreshAllIdsAndIndexes];
        [Spaces updateCurrentSpace];
        
        calculatedSpaceIndex = Spaces.currentSpaceIndex;
        NSLog(@"newcalcd %d", calculatedSpaceIndex);
        [self runShortcut: spacewindow];
    } else {
        CGPoint mouseLoc = [helperLib CGPointFromNSPoint: [NSEvent mouseLocation]];
        NSScreen* mouseScreen = [helperLib screenAtCGPoint: mouseLoc];
        NSArray* screenSpaceIds = [Spaces screenSpacesMap][[Spaces uuidForScreen: mouseScreen]];
        int startIndex = [Spaces indexWithID: [screenSpaceIds.firstObject intValue]];
        if ((calculatedSpaceIndex == startIndex && direction == Backward) || (calculatedSpaceIndex == startIndex + screenSpaceIds.count - 1 && direction == Forward)) {
            //(do nothing) if reached end, stop sending key, if reached beginning stop sending key
            //so that the above if-block can runShortcut w/ spacewindow
        } else [self runShortcut: sendKey];
    }
}
+ (void) perpetuate {
    if (!hasStarted) return;
    NSLog(@"perpetuate");
    [self sendKeyOrSpacewindow];
    int oldPerpetuationCounter = perpetuationCounter;
    setTimeout(^{if (oldPerpetuationCounter == perpetuationCounter) [self perpetuate];}, perpetuationTime);
    if (perpetuationTime == SLOWDESKTOPSWITCH_T) perpetuationTime = FASTDESKTOPSWITCH_T;
}
+ (BOOL) keyCode: (int) keyCode : (NSString*) eventString : (NSDictionary*) modifiers {
    //ctrl+left-arrow
    if ([eventString isEqual: @"keydown"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 123) return [self shortcutDown: keyCode];
    if ([eventString isEqual: @"keyup"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 123) return [self shortcutUp];
    //ctrl+right-arrow
    if ([eventString isEqual: @"keydown"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 124) return [self shortcutDown: keyCode];;
    if ([eventString isEqual: @"keyup"] && (modifiers[@"ctrl"]) && modifiers.count == 1 && keyCode == 124) return [self shortcutUp];
    return YES;
}
@end
