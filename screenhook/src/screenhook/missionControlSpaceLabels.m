//
//  missionControlSpaceLabels.m
//  screenhook
//
//  Created by Steven G on 11/8/23.
//

#import "missionControlSpaceLabels.h"
#import "../globals.h"
#import "../helperLib.h"
#import "../prefs.h"
#import "../Spaces.h"
#import "../WindowManager.h"

int screenWidth = 1920;int screenHeight = 1080;

NSWindowController* overlayController;
NSMutableArray* spaceLabels;
int windowWidth;
int windowHeight;

void showLabels(void) {
    if (overlayController.window.isVisible) return;
    [overlayController.window setIsVisible: YES];
    [missionControlSpaceLabels render];
    NSLog(@"show");
}
void hideLabels(void) {
    [overlayController.window setIsVisible: NO];
    NSLog(@"hide");
}

void loadLabelsFromPrefs(void) {
    spaceLabels = [NSMutableArray arrayWithArray: [prefs getArrayPref: @"spaceLabels"]];
    int numSpaces = (int) [Spaces spaces].count;
    if (spaceLabels.count != numSpaces) { //forget all spaces, repopulate with untitled
        spaceLabels = [NSMutableArray array];
        for (int i = 0; i < numSpaces; i++) [spaceLabels addObject: @"Untitled"];
    }
}
void renameSpace(AXUIElementRef el, NSString* newTitle) {
    NSDictionary* elDict = [helperLib elementDict: el : @{
        @"value": (id)kAXValueAttribute,
    }];
    
    //get spaceIndex
    NSString* val = elDict[@"value"];
    NSRange periodRange = [val rangeOfString: @"."];
    if (periodRange.location == NSNotFound) return;
    NSString* spaceIndexStr = [val substringToIndex: periodRange.location];
    int spaceIndex = [spaceIndexStr intValue];
    
    spaceLabels[spaceIndex] = newTitle;
    [prefs setArrayPref: @"spaceLabels" : spaceLabels];
}

@implementation missionControlSpaceLabels : NSObject
+ (void) init {
    spaceLabels = [NSMutableArray array];
    
    //create window from xib
    overlayController = [[NSWindowController alloc] initWithWindowNibName: @"spaceLabelsWindow"];
    [overlayController.window setOpaque: NO];
    [overlayController.window setBackgroundColor: [NSColor colorWithSRGBRed: 0 green: 0 blue: 0 alpha: 0.75]];
    [overlayController.window setLevel: NSPopUpMenuWindowLevel];
    
    windowWidth = screenWidth;
    windowHeight = 30;
    [overlayController.window setFrame: NSMakeRect(overlayController.window.frame.origin.x, overlayController.window.frame.origin.y, windowWidth, windowHeight) display: NO];
    [overlayController.window setFrameTopLeftPoint: NSMakePoint(0, screenHeight)];
    
    loadLabelsFromPrefs();
}
+ (void) tick: (int) exposeType {
    if (exposeType) showLabels();
    else hideLabels();
}
+ (void) clearView {
    [overlayController.window.contentView removeFromSuperview];
    [overlayController.window setContentView: [[NSView alloc] init]];
}
+ (void) render {
    [self clearView];
    NSView* view = overlayController.window.contentView;
    int paddingY = 1;
    NSView* labelsView = [[NSView alloc] initWithFrame: CGRectMake(0, paddingY, windowWidth, windowHeight - paddingY * 2)];
    int y = 0;
    int w = windowWidth / spaceLabels.count;
    int h = windowHeight;
    for (int i = 0; i < spaceLabels.count; i++) {
        int x = i * w;
        NSView* labelView = [[NSView alloc] initWithFrame: CGRectMake(x, y, w, h)];
        [labelView setWantsLayer: YES];
        [labelView.layer setBackgroundColor: NSColor.gridColor.CGColor];
        int textHeightPixels = 16;
        NSTextView* label = [[NSTextView alloc] initWithFrame: CGRectMake(0, (h - textHeightPixels) / 2, w, textHeightPixels)];
        [label setString: [[NSString stringWithFormat: @"%d. ", (i+1)] stringByAppendingString: spaceLabels[i]]];
        [label setTextColor: NSColor.whiteColor];
//        [label setAlignment: NSTextAlignmentCenter];
        [labelView addSubview: label];
        [labelsView addSubview: labelView];
    }
    [view addSubview: labelsView];
}
+ (void) labelClicked: (AXUIElementRef) el {
    NSDictionary* elDict = [helperLib elementDict: el : @{
        @"value": (id)kAXValueAttribute,
        @"role": (id)kAXRoleAttribute,
    }];
    NSLog(@"%@", elDict);
    if (![elDict[@"role"] isEqual: @"AXTextArea"]) return;
    
    [helperLib applescript: @"tell application \"System Events\" to key code 53"]; //esc (for some reason using [helperLib sendKey: 53] doesn't close consistently if mission control/macOS is bugging out)
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [helperLib applescript: @"tell application \"screenhook\" to activate"];
        setTimeout(^{
            [helperLib sendKey: 48]; //tab
            [helperLib sendKey: 48]; //tab
        }, 666);
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    //can't put in semaphore, "window creation must be in main thread" (paraphrasing)
        // Create an NSAlert instance
        NSAlert* alert = [[NSAlert alloc] init];

        // Set the title and message
        [alert setMessageText:@"Enter Name/Title"];
        [alert setInformativeText:@"Please enter a name or title:"];

        // Create an NSTextField control
        NSTextField *inputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
        [inputField setStringValue: elDict[@"value"]];
        [alert setAccessoryView:inputField];

        // Add buttons to the alert
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];

        // Display the alert
        NSInteger buttonPressed = [alert runModal];

        if (buttonPressed == NSAlertFirstButtonReturn) {
            // User clicked OK
            NSString *enteredText = [inputField stringValue];
            renameSpace(el, enteredText);
        } else {
            // User clicked Cancel or closed the dialog
            NSLog(@"Dialog canceled");
        }
}
@end
