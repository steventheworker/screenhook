//
//  desktopPeak.m
//  screenhook
//
//  Created by Steven G on 12/1/23.
//

#import "desktopPeak.h"
#import "../globals.h"
#import "../helperLib.h"
#import "../WindowManager.h"

const int CORNER_SIZE = 5; //pixels

BOOL mouseOnCorner = NO;
BOOL cornerClickStarted = NO;
BOOL cornerWasClicked = NO;

NSDate* mousedownT;

BOOL isCorner(CGPoint cursorPos) {
    NSScreen* screen = [helperLib screenWithMouse];
    NSScreen* primaryScreen = [helperLib primaryScreen];
    float offsetTop = primaryScreen.frame.size.height - (screen.frame.origin.y + screen.frame.size.height);
    if (screen == primaryScreen) {offsetTop = 0;/*offsetBottom = 0;offsetLeft = 0;*/}
    float cornerStartX = screen.frame.origin.x + screen.frame.size.width - CORNER_SIZE;
    float cornerStartY = offsetTop;
    if (cursorPos.x >= cornerStartX && cursorPos.x <= cornerStartX + CORNER_SIZE &&
        cursorPos.y >= cornerStartY && cursorPos.y <= cornerStartY + CORNER_SIZE) {
        return YES;
    }
    return NO;
}

@implementation desktopPeak
+ (void) init {
    mousedownT = NSDate.date;
}
+ (BOOL) mousedown: (AXUIElementRef) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos {
    if ([cursorDict[@"role"] isEqual: @"AXMenuBar"]) {
        NSDate* t0 = mousedownT;
        mousedownT = NSDate.date;
        float dT = (NSTimeInterval)[mousedownT timeIntervalSinceDate: t0] * 1000; //seconds to milliseconds
        if (dT < 333) { //double click menubar
            cornerWasClicked = !WindowManager.exposeType;
            [helperLib openDesktopExpose];
        }
    }
    if (mouseOnCorner) {
        cornerClickStarted = YES;
        return NO;
    }
    return YES;
}
+ (BOOL) mouseup: (AXUIElementRef) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos {
    if (cornerClickStarted) {
        cornerClickStarted = NO;
        if (mouseOnCorner) cornerWasClicked = YES;
        return NO;
    }
    return YES;
}
+ (void) mousemove: (CGPoint) cursorPos : (BOOL) isDragging {
    BOOL wasOnCorner = mouseOnCorner;
    mouseOnCorner = isCorner(cursorPos);
    if (wasOnCorner && !mouseOnCorner) { //exited corner
        if (cornerWasClicked) return; //don't exit desktop exposé
        if (isDragging) {
            cornerWasClicked = YES; //keep open
            return;
        }
        [helperLib openDesktopExpose];
    } else if (!wasOnCorner && mouseOnCorner) { //entered corner
        if (cornerWasClicked) {
            cornerWasClicked = NO;
            if (!isDragging) return;
        }
        [helperLib openDesktopExpose];
    }
}
@end
