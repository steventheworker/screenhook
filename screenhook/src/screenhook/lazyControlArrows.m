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

enum directions {Forward, Backward};
enum switchType {spacewindow, sendKey};
const int SPACESWITCHMODE_T = 666 * 2; //(ms), how long it takes for fast-switching animations to stop (at which point using spacewindow's is faster (than sendKey))
const int FASTSPACESWITCH_T = 188; //(ms) to switch again
const int SLOWSPACESWITCH_T = 400; //(ms) to switch with prevSpace/nextSpace

int calculatedSpaceIndex = 1; //the spaceindex you started at when calling the shortcuts ± the # sent prev/nextSpace/sendKey
int direction = -1;
BOOL propagateOnce = NO;

@interface queueEntry : NSObject {
    @public
    NSDate* triggerTime;
    NSDate* creationTime;
    enum directions dir0;
    enum directions dir;
    int checkpoint; //ms: SPACESWITCHMODE_T, FAST/SLOW SPACESWITCH_T
}
@end
@implementation queueEntry
+ (instancetype) init: (int)dir0 : (int)dir {
    queueEntry* entry = [[self alloc] init];
    entry->creationTime = NSDate.date;
    entry->dir0 = dir0;
    entry->dir = dir;
    return entry;
}
- (void) setTriggerTime: (queueEntry*) prev {
    self->triggerTime = [NSDate.date dateByAddingTimeInterval: 100 / 1000];
}
- (void) trigger {
    propagateOnce = YES;
    [helperLib sendKey: self->dir == Forward ? 124 : 123];
}
@end
NSMutableArray<queueEntry*>* queue;
BOOL processing = NO;
queueEntry* popped = nil;
int processEntry(queueEntry* prev, queueEntry* cur) {
    [cur setTriggerTime: prev];
    int t = [NSDate.date timeIntervalSinceDate: cur->triggerTime] * 1000; //how long to wait before running the current item in the queue
    setTimeout(^{[cur trigger];}, t);
    
    int ret = t + FASTSPACESWITCH_T; //how long to wait before processing next in queue
    //this involves looking at what's next in the queue
        //if goes to end(s) => +SLOWSPACESWITCH_T
        //if switches direction => +SPACESWITCHMODE_T
        //else +FASTSPACESWITCH_T
    return ret;
}
void process(void) {
    if (!processing) return;
    queueEntry* last = popped;
    popped = queue.firstObject;
    if (queue.count) [queue removeObjectAtIndex: 0];
    else {processing = NO;return;}
    
    setTimeout(^{process();}, processEntry(last, popped));
}
void processQueue(void) {
    if (processing) return;
    processing = YES;
    process();
}

@implementation lazyControlArrows
+ (void) init {
    calculatedSpaceIndex = Spaces.currentSpaceIndex;
    queue = NSMutableArray.array;
}
+ (BOOL) shortcutDown: (int) keyCode {
    if (propagateOnce) {return YES;}
    BOOL prevDir = direction;
    direction = keyCode == 123;
    [queue addObject: [queueEntry init: prevDir : direction]];
    processQueue();
    return NO;
}
+ (BOOL) shortcutUp {
    if (propagateOnce) {propagateOnce = NO;return YES;}
    return NO;
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
