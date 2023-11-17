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

NSMutableArray<NSWindowController*>* overlayControllers;
NSMutableArray* spaceLabels;
int windowWidth;
int windowHeight;

void showLabels(void) {
    for (NSWindowController* overlayController in overlayControllers) {
        if (overlayController.window.isVisible) return;
        [overlayController.window setIsVisible: YES];
    }
    [missionControlSpaceLabels render];
}
void hideLabels(void) {
    for (NSWindowController* overlayController in overlayControllers) {
        if (!overlayController.window.isVisible) return;
        [overlayController.window setIsVisible: NO];
    }
}

void loadLabelsFromPrefs(void) {
    spaceLabels = [NSMutableArray arrayWithArray: [prefs getArrayPref: @"spaceLabels"]];
    int numSpaces = (int) [Spaces spaces].count;
    if (spaceLabels.count == 0) { //populate with untitled
        spaceLabels = [NSMutableArray array];
        for (int i = 0; i < numSpaces; i++) [spaceLabels addObject: @"Untitled"];
    } else if (numSpaces > spaceLabels.count) {
        for (int i = (int) spaceLabels.count; i < numSpaces; i++) [spaceLabels addObject: @"Untitled"];
    } else if (numSpaces < spaceLabels.count) {
        for (int i = (int) spaceLabels.count; i > numSpaces; i--) [spaceLabels removeLastObject];
    }
}
void renameSpace(AXUIElementRef el, NSString* newTitle) {
    NSDictionary* elDict = [helperLib elementDict: el : @{
        @"value": (id)kAXValueAttribute,
        @"identifier": (id)kAXIdentifierAttribute,
    }];
    int spaceIndex = [helperLib isNaN: elDict[@"value"]] ? [elDict[@"identifier"] intValue] : [elDict[@"value"] intValue] - 1;
    spaceLabels[spaceIndex] = newTitle;
    [prefs setArrayPref: @"spaceLabels" : spaceLabels];
}

@implementation missionControlSpaceLabels : NSObject
+ (void) init {
    overlayControllers = [NSMutableArray array];
    spaceLabels = [NSMutableArray array];
    [self addOverlayWindows];
}
+ (void) tick: (int) exposeType {
    if (exposeType) showLabels();
    else hideLabels();
}
+ (void) addOverlayWindows {
    loadLabelsFromPrefs();
    NSArray* screens = [NSScreen screens];
    for (NSScreen* screen in screens) {
        //create window from xib
        NSWindowController* overlayController = [[NSWindowController alloc] initWithWindowNibName: @"spaceLabelsWindow"];
        [overlayController.window setOpaque: NO];
        [overlayController.window setBackgroundColor: NSColor.clearColor];
        [overlayController.window setLevel: NSPopUpMenuWindowLevel];
        
        windowWidth = screen.frame.size.width * 0.925;
        windowHeight = 40;
        [overlayController.window setFrame: NSMakeRect(overlayController.window.frame.origin.x, overlayController.window.frame.origin.y, windowWidth, windowHeight) display: NO];
        [overlayController.window setFrameTopLeftPoint: NSMakePoint(screen.frame.origin.x + ((screen.frame.size.width - windowWidth) / 2), screen.frame.origin.y + screen.frame.size.height)];
        
        [overlayControllers addObject: overlayController];
    }
}
+ (void) clearViews {
    for (NSWindowController* overlayController in overlayControllers) {
        [overlayController.window.contentView removeFromSuperview];
        [overlayController.window setContentView: [[NSView alloc] init]];
    }
}
+ (void) render {
    [self clearViews];
    for (NSWindowController* overlayController in overlayControllers) {
        NSView* view = overlayController.window.contentView;
        int paddingY = 1;
        NSView* labelsView = [[NSView alloc] initWithFrame: CGRectMake(0, paddingY, windowWidth, windowHeight - paddingY * 2)];
        int y = 0;
        int w = windowWidth / spaceLabels.count;
        int h = windowHeight;
        for (int i = 0; i < spaceLabels.count; i++) {
            int x = i * w;
            NSView* labelContainer = [[NSView alloc] initWithFrame: CGRectMake(x, y, w, h)];
            //        [labelContainer setWantsLayer: YES];
            //        [labelContainer.layer setBackgroundColor: NSColor.gridColor.CGColor];
            int textHeightPixels = 16;
            NSString* spaceNumberStr = [NSString stringWithFormat: @"%d", (i+1)];
            float spaceNumberW = textHeightPixels * 0.6 * (spaceNumberStr.length * 1.2);
            int spaceNumY = (h - textHeightPixels) + textHeightPixels * 0.6 + -5;
            if ([spaceLabels[i] length] > 16) spaceNumY += 2; //if multi-line, shift spaceNumber up
            NSTextView* spaceNumber = [[NSTextView alloc] initWithFrame: CGRectMake(w/2 - spaceNumberW/2, spaceNumY, spaceNumberW, textHeightPixels * 0.6)];
            [spaceNumber setString: spaceNumberStr];
            [spaceNumber setTextColor: NSColor.whiteColor];
            [spaceNumber setFont: [NSFont fontWithName: @"Helvetica" size: textHeightPixels * 0.6]];
            [spaceNumber setBackgroundColor: NSColor.clearColor];
            
            if ([spaceLabels[i] length] > 16) textHeightPixels *= 1.8; //overflowing string ? double height... //todo: don't hardcode
            NSTextView* label = [[NSTextView alloc] initWithFrame: CGRectMake(0, (h - textHeightPixels) / 2, w, textHeightPixels)];
            [label setString: spaceLabels[i]];
            [label setTextColor: NSColor.whiteColor];
            [label setAlignment: NSTextAlignmentCenter];
            [label setBackgroundColor: NSColor.clearColor];
            [label setIdentifier: [NSString stringWithFormat: @"%d", i]];
            
            [labelContainer addSubview: label];
            [labelContainer addSubview: spaceNumber];
            [labelsView addSubview: labelContainer];
        }
        [view addSubview: labelsView];
    }
}
+ (void) labelClicked: (AXUIElementRef) el {
    NSDictionary* elDict = [helperLib elementDict: el : @{
        @"value": (id)kAXValueAttribute,
        @"role": (id)kAXRoleAttribute,
        @"identifier": (id)kAXIdentifierAttribute,
    }];
    NSLog(@"%@", elDict);
    if (![elDict[@"role"] isEqual: @"AXTextArea"]) return;
    
    [helperLib applescript: @"tell application \"System Events\" to key code 53"]; //esc (for some reason using [helperLib sendKey: 53] doesn't close consistently if mission control/macOS is bugging out)
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        setTimeout(^{ //focus the input (for some reason the applescript below doesn't work (says dialog DNE, but works fine in script editor, so use send tab key instead)
            [helperLib applescript: @"tell application \"screenhook\" to activate"];
            [helperLib sendKey: 48]; //tab
            [helperLib sendKey: 48]; //tab
//          [helperLib applescript: @"tell application \"System Events\"\n\
//                    tell process \"screenhook\"\n\
//                        if exists (first window whose subrole = \"AXDialog\") then\n\
//                            tell (first window whose subrole = \"AXDialog\")\n\
//                                set focused of text field 1 to true\n\
//                            end tell\n\
//                        else\n\
//                            return \"DNE\"\n\
//                        end if\n\
//                    end tell\n\
//                end tell"];
        }, 666);
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

    NSString* spaceName;
    NSString* spaceIndexStr;
    if ([elDict[@"value"] length] > 2 || [helperLib isNaN: elDict[@"value"]]) { //clicked on the space title / label
        spaceName = elDict[@"value"];
        spaceIndexStr = [NSString stringWithFormat: @"%d", [elDict[@"identifier"] intValue] + 1];
    } else { //clicked on the spacenumber
        spaceIndexStr = elDict[@"value"];
        spaceName = spaceLabels[[spaceIndexStr intValue] - 1];
    }

    //Create an NSAlert instance - can't put in semaphore, "window creation must be in main thread" (paraphrasing)
    NSAlert* alert = [[NSAlert alloc] init];

    // Set the title and message
    [alert setMessageText:@"Title for space:"];
    [alert setInformativeText: spaceIndexStr];

    // Create an NSTextField control
    NSTextField *inputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [inputField setStringValue: spaceName];
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
    setTimeout(^{
        [helperLib openMissionControl];
    }, 333);
}
+ (void) reshow {
    for (NSWindowController* overlayController in overlayControllers) if (overlayController.window.isVisible) [overlayController close]; //window won't be on top unless it's recreated
    overlayControllers = [NSMutableArray array];
    [self addOverlayWindows];
    showLabels(); //reshow
}
+ (void) mouseup { //test for space changes (see if a space was added,removed (and reflect it into "spaceLabels"))
    setTimeout(^{
        [Spaces refreshAllIdsAndIndexes];
        NSLog(@"%lu", (unsigned long)[Spaces spaces].count);
        //a window dragndropped into another space hides the window, reshow here, since haven't found way to detect window changing space/dragdrop
        [self reshow];
    }, 100);
}
+ (void) spaceChanged: (NSNotification*) note {
    [self reshow];
}
@end
