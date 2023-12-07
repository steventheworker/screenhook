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
#import "screenhook.h"

NSMutableArray<NSWindowController*>* overlayControllers;
NSMutableArray* spaceLabels;
NSMutableDictionary* monitorSpaceLabels; //monitorSpaceLabels[uuid]   --when a monitor is attached/detached, the first space of that monitor is freshly created/removed. we remember the last cached spaceLabel for it here
int windowWidth;
int windowHeight;
NSScreen* primaryScreen;

void showLabelWindows(void) {
    for (NSWindowController* overlayController in overlayControllers) {
        if (overlayController.window.isVisible) return;
        [overlayController.window setIsVisible: YES];
    }
    [missionControlSpaceLabels render];
}
void hideLabelWindows(void) {
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
NSArray* spaceLabelsForMonitor(NSArray* screenSpaceIds) {
    NSMutableArray* ret = [NSMutableArray array];
    for (NSNumber* spaceId in screenSpaceIds) {
        int i = [Spaces indexWithID: spaceId.intValue] - 1;
        [ret addObject: i > spaceLabels.count - 1 ? @"Untitled" : spaceLabels[i]];
    }
    return ret;
}

void renameSpace(AXUIElementRef el, NSString* newTitle) {
    NSDictionary* elDict = [helperLib elementDict: el : @{
        @"value": (id)kAXValueAttribute,
        @"identifier": (id)kAXIdentifierAttribute,
    }];
    int spaceId = [elDict[@"identifier"] intValue];
    int spaceIndex = [Spaces indexWithID: spaceId] - 1;
        
    spaceLabels[spaceIndex] = newTitle;
    [prefs setArrayPref: @"spaceLabels" : spaceLabels];
}

@implementation missionControlSpaceLabels : NSObject
+ (void) init {
    overlayControllers = [NSMutableArray array];
    spaceLabels = [NSMutableArray array];
    monitorSpaceLabels = [NSMutableDictionary dictionaryWithDictionary: [prefs getDictPref: @"monitorSpaceLabels"]];
    primaryScreen = [helperLib primaryScreen];
    [self addOverlayWindows];
}
+ (void) tick: (int) exposeType {
    if (exposeType) showLabelWindows();
    else hideLabelWindows();
}
+ (void) addOverlayWindows {
    loadLabelsFromPrefs();
    for (NSScreen* screen in NSScreen.screens) {
        //create window from xib
        NSWindowController* overlayController = [[NSWindowController alloc] initWithWindowNibName: @"spaceLabelsWindow"];
        [overlayController.window setOpaque: NO];
        [overlayController.window setBackgroundColor: NSColor.clearColor];
        [overlayController.window setLevel: NSPopUpMenuWindowLevel];
        
        windowWidth = screen.frame.size.width * 0.925;
        windowHeight = 40;
        [overlayController.window setFrame: NSMakeRect(overlayController.window.frame.origin.x, overlayController.window.frame.origin.y, windowWidth, windowHeight) display: NO];
        [overlayController.window setFrameTopLeftPoint: NSMakePoint(screen.frame.origin.x + ((screen.frame.size.width - windowWidth) / 2), screen.frame.origin.y + screen.frame.size.height)];
        [overlayController.window setIdentifier: [Spaces uuidForScreen: screen]];
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
        NSArray* screenSpaces = [Spaces screenSpacesMap][overlayController.window.identifier];
        NSView* view = overlayController.window.contentView;
        int paddingY = 1;
        NSSize windowSize = overlayController.window.frame.size;
        NSView* labelsView = [[NSView alloc] initWithFrame: CGRectMake(0, paddingY, windowSize.width, windowSize.height - paddingY * 2)];
        NSArray* labelsForMonitor = spaceLabelsForMonitor(screenSpaces);
        for (int i = 0; i < screenSpaces.count; i++) {
            int y = 0;
            int w = windowSize.width / screenSpaces.count;
            int h = windowSize.height;
            int x = i * w;
            if (screenSpaces.count >= 1 && screenSpaces.count <= 7) { //account for variable spacing (when less than 8 spaces)
                //each preview is 8.1% of the window width (7.5% (.075) of the screen width) (window width is 0.925 of the screen width)     ---with 3.15% betweeen previews
                w = (.1081*windowSize.width); //144/(windowWidth (.925 of screen))
                int maxSpacing = .02504*windowSize.width;
                int spacing = maxSpacing;
                int allPreviewWidths = w*(int)screenSpaces.count + spacing*((int)screenSpaces.count-1);
                int remainingWidth = windowSize.width - allPreviewWidths;
                x = remainingWidth/2 + w*i + spacing*i;
            }
            NSView* labelContainer = [[NSView alloc] initWithFrame: CGRectMake(x, y, w, h)];
            //        [labelContainer setWantsLayer: YES];
            //        [labelContainer.layer setBackgroundColor: NSColor.gridColor.CGColor];
            int textHeightPixels = 16;
            NSString* spaceNumberStr = [NSString stringWithFormat: @"%d", (i+1)];
            float spaceNumberW = textHeightPixels * 0.6 * (spaceNumberStr.length * 1.2);
            int spaceNumY = (h - textHeightPixels) + textHeightPixels * 0.6 + -5;
            if ([labelsForMonitor[i] length] > 16) spaceNumY += 2; //if multi-line, shift spaceNumber up
            NSTextView* spaceNumber = [[NSTextView alloc] initWithFrame: CGRectMake(w/2 - spaceNumberW/2, spaceNumY, spaceNumberW, textHeightPixels * 0.6)];
            [spaceNumber setString: spaceNumberStr];
            [spaceNumber setTextColor: NSColor.whiteColor];
            [spaceNumber setFont: [NSFont fontWithName: @"Helvetica" size: textHeightPixels * 0.6]];
            [spaceNumber setBackgroundColor: NSColor.clearColor];
            [spaceNumber setIdentifier: [NSString stringWithFormat: @"%d", [screenSpaces[i] intValue]]];
            
            if ([labelsForMonitor[i] length] > 16) textHeightPixels *= 1.8; //overflowing string ? double height... //todo: don't hardcode
            NSTextView* label = [[NSTextView alloc] initWithFrame: CGRectMake(0, (h - textHeightPixels) / 2, w, textHeightPixels)];
            [label setString: labelsForMonitor[i]];
            [label setTextColor: NSColor.whiteColor];
            [label setAlignment: NSTextAlignmentCenter];
            [label setBackgroundColor: NSColor.clearColor];
            [label setIdentifier: [NSString stringWithFormat: @"%d", [screenSpaces[i] intValue]]];
            
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

    int spaceId = [elDict[@"identifier"] intValue];
    int spaceIndex = [Spaces indexWithID: spaceId];
    NSString* spaceName = spaceLabels[spaceIndex - 1];
    
    //Create an NSAlert instance - can't put in semaphore, "window creation must be in main thread" (paraphrasing)
    NSAlert* alert = [[NSAlert alloc] init];

    // Set the title and message
    [alert setMessageText:@"Title for space:"];
    [alert setInformativeText: [NSString stringWithFormat: @"%d", spaceIndex]];

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
+ (void) setLabel: (int) spaceindex : (NSString*) newLabel {
    [spaceLabels setObject: newLabel atIndexedSubscript: spaceindex - 1];
    [prefs setArrayPref: @"spaceLabels" : spaceLabels];
}
+ (void) reshow {
    for (NSWindowController* overlayController in overlayControllers) if (overlayController.window.isVisible) [overlayController close]; //window won't be on top unless it's recreated
    overlayControllers = [NSMutableArray array];
    [self addOverlayWindows];
    showLabelWindows(); //reshow
}
+ (BOOL) mousedown: (AXUIElementRef) cursorEl : (NSDictionary*) cursorDict : (CGPoint) cursorPos {
    if (NSRunningApplication.currentApplication.processIdentifier == [cursorDict[@"pid"] intValue] && cursorPos.y <= 100) { //space labels are at the top, w/o cursorPos check, interacting w/ screenhook windows in mission control is disabled!
        [self labelClicked: cursorEl];
        return NO; //preventDefault
    }
    return YES;
}
+ (void) mouseup {
    NSDictionary* screenSpacesMap1 = [[Spaces screenSpacesMap] copy];
    //check for any space changes
    setTimeout(^{
        [Spaces refreshAllIdsAndIndexes];
        NSDictionary* screenSpacesMap2 = [Spaces screenSpacesMap];
        for (NSString* screenUUID in screenSpacesMap1) {
            NSArray* screenSpaces1 = screenSpacesMap1[screenUUID];
            NSArray* screenSpaces2 = screenSpacesMap2[screenUUID];
            if (screenSpaces2.count > screenSpaces1.count) {
                //space added (space can only be added to end)
                int lastIndex = [Spaces indexWithID: [screenSpaces1[screenSpaces1.count - 1] intValue]];
                [screenhook spaceadded: lastIndex + 1];
                [spaceLabels insertObject: @"Untitled" atIndex: lastIndex];
                [prefs setArrayPref: @"spaceLabels" : spaceLabels];
            } else if (screenSpaces2.count < screenSpaces1.count) {
                //space removed (any index could be removed)
                int i = 0;for (NSNumber* spaceId in screenSpaces1) { //i = relative index (to screenSpaces) for removed space
                    if (![screenSpaces2 containsObject: spaceId]) break; //found the removed spaceId
                    i++;
                }
                int spaceIndex; //index to remove
                if (i == 0) spaceIndex = [Spaces indexWithID: [screenSpaces1[1] intValue]] - 1;
                else spaceIndex = [Spaces indexWithID: [screenSpaces1[0] intValue]] - 1 + i;
                [screenhook spaceremoved: spaceIndex + 1];
                [spaceLabels removeObjectAtIndex: spaceIndex];
                [prefs setArrayPref: @"spaceLabels" : spaceLabels];
            } else {
                //space dropped into index
                NSMutableArray* newIndexing = [NSMutableArray array];
                for (NSNumber* newValue in screenSpaces2) {
                    int i;for (i = 0; i < screenSpaces1.count; i++) if (screenSpaces1[i] == newValue) break;
                    [newIndexing addObject: @(i)];
                }
                BOOL didSpacesChange = NO; //if newIndexing is sorted (ie: 0,1,2,..,n), nothing changed
                for (int i = 0; i < (int)newIndexing.count; i++) if (i != [newIndexing[i] intValue]) {didSpacesChange = YES;break;}
                if (!didSpacesChange) continue;
                int monitorStartIndex = [Spaces indexWithID: [screenSpaces2[0] intValue]] - 1;
                [screenhook spacemoved: monitorStartIndex + 1 : newIndexing];
                //reflect the new indexing on the space labels
                NSArray* labelsCopy = spaceLabels.copy;
                for (int i = 0; i < newIndexing.count; i++) spaceLabels[i + monitorStartIndex] = labelsCopy[monitorStartIndex + [newIndexing[i] intValue]];
                [prefs setArrayPref: @"spaceLabels" : spaceLabels];
            }
        }
        [self reshow];
    }, 100);
}
+ (void) spaceChanged: (NSNotification*) note {
    if ([WindowManager exposeType]) [self reshow];
}
+ (void) processScreens: (NSScreen*) screen : (CGDisplayChangeSummaryFlags) flags : (NSString*) uuid {
    //if you plug a monitor in, macOS will send kCGDisplayAddFlag, kCGDisplayRemoveFlag, kCGDisplayAddFlag back-to-back ._.
    NSLog(@"scr ct %d flags %d uuid %@", NSScreen.screens.count, flags, uuid);
    if (flags & kCGDisplaySetMainFlag) primaryScreen = screen;
    if (flags & kCGDisplayAddFlag) {NSLog(@"addscreen%fx%f", screen.frame.size.width,screen.frame.size.height);
        //insert added screens monitorNewSpaceLabel into spaceLabels
        setTimeout(^{
            if (screen == primaryScreen) { //added monitor is new primary
                
                return NSLog(@"added monitor is new primary");
            }
            int firstSpaceId = [Spaces screenSpacesMap][uuid].firstObject.intValue;
            int firstLabelIndex = [Spaces indexWithID: firstSpaceId] - 1;
            NSString* monitorLabel = monitorSpaceLabels[uuid];
            [spaceLabels insertObject: monitorLabel.length ? monitorLabel : @"Untitled" atIndex: firstLabelIndex];
            [prefs setArrayPref: @"spaceLabels" : spaceLabels];
            //[prefs setDictPref: @"monitorSpaceLabels" : monitorSpaceLabels];
        }, 100);
    } else if (flags & kCGDisplayRemoveFlag) {NSLog(@"removescreen %fx%f scrct %d", screen.frame.size.width,screen.frame.size.height, NSScreen.screens.count);
        //remove removed screens label from spaceLabels, cache its monitorSpaceLabel[uuid]
        if (screen == primaryScreen) { //added monitor is new primary
            
            return NSLog(@"removed monitor was primary");
        }
        return;//removeline
        int firstSpaceId = [Spaces screenSpacesMap][uuid].firstObject.intValue;
        int firstLabelIndex = [Spaces indexWithID: firstSpaceId] - 1;
        monitorSpaceLabels[uuid] = spaceLabels[firstLabelIndex];
        [spaceLabels removeObjectAtIndex: firstLabelIndex];
        [prefs setArrayPref: @"spaceLabels" : spaceLabels];
        [prefs setDictPref: @"monitorSpaceLabels" : monitorSpaceLabels];
    }
}
@end
