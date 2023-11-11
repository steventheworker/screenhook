//
//  Spaces.m - corresponds to alt-tab-macos's "Spaces.swift"
//  Dock Expose
//
//  Created by Steven G on 10/13/23.
//

#import "Spaces.h"

int receivedCGSMainConnectID;
/*static UInt64 */ int currentSpaceId;
/*static UInt64 */ int currentSpaceIndex;
/*static*/ NSMutableArray* visibleSpaces;
/*static*/ NSMutableDictionary<NSString*, NSArray<NSNumber*>*>* screenSpacesMap;
/*static*/ NSMutableArray* idsAndIndexes;

/*
     NSWorkspace.shared.notificationCenter.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: nil, using: { _ in
         debugPrint("OS event", "didChangeScreenParametersNotification")
         refreshAllIdsAndIndexes()
     })
*/

NSString* uuidForScreen(NSScreen* screen) {
    CGDirectDisplayID displayID = [[screen deviceDescription][@"NSScreenNumber"] unsignedIntValue];
    CFUUIDRef screenUUID = CGDisplayCreateUUIDFromDisplayID(displayID);
    if (screenUUID != NULL) {
        currentSpaceId = CGSManagedDisplayGetCurrentSpace((int)receivedCGSMainConnectID, CFUUIDCreateString(NULL, screenUUID));
    }
    return nil;
}

@implementation Spaces
+ (int) CGSMainConnectID {return receivedCGSMainConnectID;}
+ (int) currentSpaceId {return currentSpaceId;}
+ (int) currentSpaceIndex {return currentSpaceIndex;}
+ (void) init: (int) cgsMainConnectionId {
    receivedCGSMainConnectID = cgsMainConnectionId;
    currentSpaceId = 1;
    currentSpaceIndex = 1;
    visibleSpaces = [NSMutableArray arrayWithArray: @[/* CGSSpaceID */]];
    screenSpacesMap = [NSMutableDictionary dictionaryWithDictionary: @{/* {ScreenUuid: CGSSpaceID} */}];
    idsAndIndexes = [NSMutableArray arrayWithArray: @[/* [CGSSpaceID, SpaceIndex] */]];
    [self refreshAllIdsAndIndexes];
    [self updateCurrentSpace];
}
+ (void) refreshAllIdsAndIndexes {
    [idsAndIndexes removeAllObjects];
    [screenSpacesMap removeAllObjects];
    [visibleSpaces removeAllObjects];
    int spaceIndex = 1;
    NSDictionary* dict = (__bridge NSDictionary*)(CGSCopyManagedDisplaySpaces(receivedCGSMainConnectID));
    for (NSDictionary* screen in dict) {
        NSString* display = screen[@"Display Identifier"];
        if ([display isEqual: @"Main"]) {
            NSScreen* mainScreen = [NSScreen mainScreen];
            if (mainScreen) {
                NSUUID* mainUuid = uuidForScreen(mainScreen);
                if (mainUuid) display = mainUuid.UUIDString;
            }
        }
//        (screen["Spaces"] as! [NSDictionary]).forEach { (space: NSDictionary) in
//            let spaceId = space["id64"] as! CGSSpaceID
//            idsAndIndexes.append((spaceId, spaceIndex))
//            screenSpacesMap[display, default: []].append(spaceId)
//            spaceIndex += 1
//        }
        for (NSDictionary* space in screen[@"Spaces"]) {
            int spaceId = [space[@"id64"] intValue];
            [idsAndIndexes addObject: @[@(spaceId), @(spaceIndex)]];
            if (screenSpacesMap[display]) {
                NSMutableArray* spaceIds = [NSMutableArray arrayWithArray: screenSpacesMap[display]];
                [spaceIds addObject: @(spaceId)];
                screenSpacesMap[display] = spaceIds;
            } else screenSpacesMap[display] = @[@(spaceId)];
            spaceIndex++;
        }

        [visibleSpaces addObject: [[screen objectForKey: @"Current Space"] objectForKey: @"id64"]]; //visibleSpaces.append((screen["Current Space"] as! NSDictionary)["id64"] as! CGSSpaceID)
    }
}
+ (void) refreshCurrentSpaceId {
    NSScreen* mainScreen = [NSScreen mainScreen];
    if (mainScreen) { // it seems that in some rare scenarios, some of these values are nil; we wrap to avoid crashing
        NSUUID* uuid = (NSUUID*)uuidForScreen(mainScreen);
//        NSLog(@"UUID '%@'", uuid);
        if (uuid) currentSpaceId = CGSManagedDisplayGetCurrentSpace(receivedCGSMainConnectID, [uuid.UUIDString UTF8String]);
    }
}
+ (void) updateCurrentSpace {
    [self refreshCurrentSpaceId];
    for (NSArray* tuple in idsAndIndexes) { //    currentSpaceIndex = idsAndIndexes.first {    (spaceId: CGSSpaceID, _) -> Bool in spaceId == currentSpaceId    }?.1 ?? SpaceIndex(1)
        int spaceId = [tuple[0] intValue];
        if (spaceId == currentSpaceId) {
            currentSpaceIndex = [tuple[1] intValue];
            break; // Exit the loop once a match is found
        }
    }
//    NSLog(@"Current space %d", (int)currentSpaceId);
}
+ (NSArray<NSNumber* /* CGSSpaceID */>*) spaces {return idsAndIndexes;}
+ (NSArray<NSNumber* /* CGSSpaceID */>*) otherSpaces {
    NSMutableArray* filteredIds = [NSMutableArray array]; // return idsAndIndexes.filter { $0.0 != currentSpaceId }.map { $0.0 }
    for (NSArray* tuple in idsAndIndexes) if ([tuple[0] intValue] != currentSpaceId) [filteredIds addObject:tuple[0]];
    return filteredIds;
}
+ (NSArray<NSNumber* /* CGWindowID */>*) windowsInSpaces: (NSArray*) spaces : (BOOL) includeInvisible {
    CGSCopyWindowsTags set_tags = 0; //var set_tags = ([] as CGSCopyWindowsTags).rawValue
    CGSCopyWindowsTags clear_tags = 0; //var clear_tags = ([] as CGSCopyWindowsTags).rawValue
    CGSCopyWindowsOptions options = (CGSCopyWindowsOptions)CGSCopyWindowsOptionsScreenSaverLevel1000; //var options = [.screenSaverLevel1000] as CGSCopyWindowsOptions
    if (includeInvisible) {//if includeInvisible {
        options |= (CGSCopyWindowsOptionsInvisible1 | CGSCopyWindowsOptionsInvisible2);// options = [options, .invisible1, .invisible2]
    }//}
    return (__bridge NSArray*)CGSCopyWindowsWithOptionsAndTags(receivedCGSMainConnectID, 0, (__bridge CFArrayRef)spaces, options, &set_tags, &clear_tags);
//    return (NSArray*)CGSCopyWindowsWithOptionsAndTags(receivedCGSMainConnectID, 0, (CFArrayRef*)spaceIds, options.rawValue, &set_tags, &clear_tags);
    
}
+ (BOOL) isSingleSpace {return idsAndIndexes.count == 1;}
@end
