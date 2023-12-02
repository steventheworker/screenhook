//
//  desktopPeak.m
//  screenhook
//
//  Created by Steven G on 12/1/23.
//

#import "desktopPeak.h"
#import "../globals.h"
#import "../helperLib.h"

const int CORNER_SIZE = 5; //pixels

BOOL mouseOnCorner = NO;
BOOL cornerClickStarted = NO;
BOOL cornerWasClicked = NO;

BOOL isCorner(CGPoint cursorPos) {
    NSScreen* screen = [helperLib screenWithMouse];
    float cornerStartX = screen.frame.origin.x + screen.frame.size.width - CORNER_SIZE;
    float cornerStartY = screen.frame.origin.y;
    if (cursorPos.x >= cornerStartX && cursorPos.x <= cornerStartX + CORNER_SIZE &&
        cursorPos.y >= cornerStartY && cursorPos.y <= cornerStartY + CORNER_SIZE) {
        return YES;
    }
    return NO;
}

@implementation desktopPeak
+ (void) init {
    
}
+ (BOOL) mousedown: (AXUIElementRef) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos {
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
        if (isDragging) cornerWasClicked = YES; //keep open
        else [helperLib openDesktopExpose];
    } else if (!wasOnCorner && mouseOnCorner) { //entered corner
        if (cornerWasClicked) {cornerWasClicked = NO;return;} //reset cornerWasClicked
        [helperLib openDesktopExpose];
    }
}
@end
