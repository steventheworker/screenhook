//
//  Spaces.h
//  Dock Expose
//
//  Created by Steven G on 10/13/23.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, CGSSpaceMask) {
    CGSSpaceMaskCurrent = 5,
    CGSSpaceMaskOther = 6,
    CGSSpaceMaskAll = 7
};
extern NSArray* _Nonnull CGSCopySpacesForWindows(int cid, int mask, NSArray* _Nonnull wids); // private api fallback


typedef NS_OPTIONS(NSInteger, CGSCopyWindowsOptions) {
    CGSCopyWindowsOptionsInvisible1 = 1 << 0,
    CGSCopyWindowsOptionsScreenSaverLevel1000 = 1 << 1,
    CGSCopyWindowsOptionsInvisible2 = 1 << 2,
    CGSCopyWindowsOptionsUnknown1 = 1 << 3,
    CGSCopyWindowsOptionsUnknown2 = 1 << 4,
    CGSCopyWindowsOptionsDesktopIconWindowLevel2147483603 = 1 << 5
};
typedef NS_OPTIONS(NSInteger, CGSCopyWindowsTags) {
    CGSCopyWindowsTagsLevel0 = 1 << 0,
    CGSCopyWindowsTagsNoTitleMaybePopups = 1 << 1,
    CGSCopyWindowsTagsUnknown1 = 1 << 2,
    CGSCopyWindowsTagsMainMenuWindowAndDesktopIconWindow = 1 << 3,
    CGSCopyWindowsTagsUnknown2 = 1 << 4
};
//CGSCopyWindowsOptions const screenSaverLevel1000 = (1 << 1);
//CGSCopyWindowsOptions const Invisible1 = (1 << 0);
//CGSCopyWindowsOptions const Invisible2 = (1 << 2);
//CGSCopyWindowsOptions const Unknown1 = (1 << 3);
//CGSCopyWindowsOptions const Unknown2 = (1 << 4);
//CGSCopyWindowsOptions const CGSCopyWindowsOptionsDesktopIconWindowLevel2147483603 = (1 << 5);



typedef int CGSConnection;
typedef int CGSWindow;
typedef int CGSValue;
// XXX: Undocumented private API to move the given windows (CGWindowIDs) to the given space
void CGSMoveWindowsToManagedSpace(int cid, CFArrayRef _Nullable windowIds, int spaceId);
// returns an array of window IDs (as UInt32) for the space(s) provided as `spaces`
// the elements of the array are ordered by the z-index order of the windows in each space, with some exceptions where spaces mix
// * macOS 10.10+
extern CFArrayRef _Nullable CGSCopyWindowsWithOptionsAndTags(int cid, uint32_t owner, CFArrayRef _Nullable spaces, uint32_t options, uint64_t * _Nullable set_tags, uint64_t * _Nullable clear_tags);
extern int CGSMainConnectionID(void);
//extern CGError CGSGetConnectionPSN(int cid, ProcessSerialNumber *psn);
//extern CGError CGSSetWindowAlpha(int cid, uint32_t wid, float alpha);
//extern CGError CGSSetWindowListAlpha(int cid, const uint32_t *window_list, int window_count, float alpha, float duration);
//extern CGError CGSSetWindowLevelForGroup(int cid, uint32_t wid, int level);
//extern OSStatus CGSMoveWindowWithGroup(const int cid, const uint32_t wid, CGPoint *point);
//extern CGError CGSReassociateWindowsSpacesByGeometry(int cid, CFArrayRef window_list);
//extern CGError CGSGetWindowOwner(int cid, uint32_t wid, int *window_cid);
//extern CGError CGSSetWindowTags(int cid, uint32_t wid, const int tags[2], size_t maxTagSize);
//extern CGError CGSClearWindowTags(int cid, uint32_t wid, const int tags[2], size_t maxTagSize);
//extern CGError CGSGetWindowBounds(int cid, uint32_t wid, CGRect *frame);
//extern CGError CGSGetWindowTransform(int cid, uint32_t wid, CGAffineTransform *t);
//extern CGError CGSSetWindowTransform(int cid, uint32_t wid, CGAffineTransform t);
//extern void CGSManagedDisplaySetCurrentSpace(int cid, CFStringRef display_ref, uint64_t spid);
extern uint64_t CGSManagedDisplayGetCurrentSpace(int cid, CFStringRef _Nullable display_ref);
extern CFArrayRef _Nullable CGSCopyManagedDisplaySpaces(const int cid);
//extern CFStringRef CGSCopyManagedDisplayForSpace(const int cid, uint64_t spid);
//extern void CGSShowSpaces(int cid, CFArrayRef spaces);
//extern void CGSHideSpaces(int cid, CFArrayRef spaces);
//extern CFArrayRef CGSCopyWindowsWithOptionsAndTags(int cid, uint32_t owner, CFArrayRef spaces, uint32_t options, uint64_t *set_tags, uint64_t *clear_tags);
//extern CFArrayRef CGSCopySpacesForWindows(int cid, int selector, CFArrayRef window_list);
//extern CGError CGSOrderWindowList(int cid, const uint32_t *window_list, const int *window_order, const uint32_t *window_rel, int window_count);
//extern CGError CGSRequestNotificationsForWindows(int cid, uint32_t *window_list, int window_count);
//extern CGSConnection _CGSDefaultConnection(void);
//extern OSStatus CGSGetWindowCount(const CGSConnection cid, CGSConnection targetCID, int* outCount);
//extern OSStatus CGSGetWindowList(const CGSConnection cid, CGSConnection targetCID, int count, int* list, int* outCount);
//extern OSStatus CGSGetOnScreenWindowCount(const CGSConnection cid, CGSConnection targetCID, int* outCount);
//extern OSStatus CGSGetOnScreenWindowList(const CGSConnection cid, CGSConnection targetCID, int count, int* list, int* outCount);
//extern OSStatus CGSGetWindowLevel(const CGSConnection cid, CGSWindow wid,  int *level);
//extern OSStatus CGSGetScreenRectForWindow(const CGSConnection cid, CGSWindow wid, CGRect *outRect);
//extern OSStatus CGSGetWindowOwner(const CGSConnection cid, const CGSWindow wid, CGSConnection *ownerCid);
//extern OSStatus CGSConnectionGetPID(const CGSConnection cid, pid_t *pid, const CGSConnection ownerCid);
//extern OSStatus CGSGetConnectionIDForPSN(const CGSConnection cid, ProcessSerialNumber *psn, CGSConnection *out);
//typedef uint64_t CGSSpace;
//typedef enum _CGSSpaceType {
//    kCGSSpaceUser,
//    kCGSSpaceFullscreen,
//    kCGSSpaceSystem,
//    kCGSSpaceUnknown
//} CGSSpaceType;
//typedef enum _CGSSpaceSelector {
//    kCGSSpaceCurrent = 5,
//    kCGSSpaceOther = 6,
//    kCGSSpaceAll = 7
//} CGSSpaceSelector;
//
//extern CFArrayRef CGSCopySpaces(const CGSConnection cid, CGSSpaceSelector type);
//extern CFArrayRef CGSCopySpacesForWindows(const CGSConnection cid, CGSSpaceSelector type, CFArrayRef windows);
//extern CGSSpaceType CGSSpaceGetType(const CGSConnection cid, CGSSpace space);
//
//extern CFNumberRef CGSWillSwitchSpaces(const CGSConnection cid, CFArrayRef a);
//extern void CGSHideSpaces(const CGSConnection cid, NSArray* spaces);
//extern void CGSShowSpaces(const CGSConnection cid, NSArray* spaces);
//
extern void CGSAddWindowsToSpaces(const CGSConnection cid, CFArrayRef _Nullable windows, CFArrayRef _Nullable spaces);
extern void CGSRemoveWindowsFromSpaces(const CGSConnection cid, CFArrayRef _Nullable windows, CFArrayRef _Nullable spaces);
//extern OSStatus CGSMoveWorkspaceWindowList(const CGSConnection connection, CGSWindow *wids, int count, int toWorkspace);
//
//typedef uint64_t CGSManagedDisplay;
//extern CGSManagedDisplay kCGSPackagesMainDisplayIdentifier;
//extern void CGSManagedDisplaySetCurrentSpace(const CGSConnection cid, CGSManagedDisplay display, CGSSpace space);
/************************************************************************************************/
//extern CGError CGSRegisterConnectionNotifyProc(int cid, connection_callback *handler, uint32_t event, void *context);
//CG_EXTERN CGError CGSNewWindow(CGSConnectionID cid, int /* use 0x3 */, float, float, CGSRegionRef, CGSWindowID *);
//CG_EXTERN CGError CGSNewWindowWithOpaqueShape(CGSConnectionID cid, int backingType /* use 0x3 */, CGSRegionRef region, CGSRegionRef opaqueShape, int flags, const int tags[2], size_t maxTagSize /* use 0x40 */, CGSWindowID *outWID);
//CG_EXTERN CGError CGSNewEmptyRegion(CGSRegionRef *outRegion);
//CG_EXTERN CGError CGSNewRegionWithRect(const CGRect *rect, CGSRegionRef *newRegion);
//CG_EXTERN CGError CGSOrderWindow(CGSConnectionID cid, CGSWindowID win, CGSWindowOrderingMode place, CGSWindowID relativeToWindow /* nullable */);
//CG_EXTERN CGError CGSSetWindowProperty(CGSConnectionID cid, CGSWindowID wid, CGSValue key, CGSValue value);
//CG_EXTERN CGError CGSSetWindowTags(CGSConnectionID cid, CGSWindowID wid, const int tags[2], size_t maxTagSize /* use 0x40 */);
//CG_EXTERN CGError CGSSetWindowOpacity(CGSConnectionID cid, CGSWindowID wid, bool isOpaque);
//CG_EXTERN CGSConnectionID CGSMainConnectionID();
//CG_EXTERN CGError CGSAddSurface(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID *sid);
//CG_EXTERN CGError CGSSetSurfaceBounds(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid, CGRect rect);
//CG_EXTERN CGError CGSOrderSurface(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid, int a, int b);
//CG_EXTERN CGError CGSSetSurfaceOpacity(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid, bool isOpaque);
//CG_EXTERN CGError CGSSetSurfaceResolution(CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid, double scale);
//CG_EXTERN CGError CGSMoveWindow(CGSConnectionID cid, CGSWindowID wid, CGPoint *point);
//CG_EXTERN CGLError CGLSetSurface(CGLContextObj gl, CGSConnectionID cid, CGSWindowID wid, CGSSurfaceID sid);
//CG_EXTERN CGSSpaceID CGSSpaceCreate(CGSConnectionID cid, int flags, CFDictionaryRef options);
//CG_EXTERN void CGSSpaceDestroy(CGSConnectionID cid, CGSSpaceID sid);
//CG_EXTERN CGError CGSSpaceSetName(CGSConnectionID cid, CGSSpaceID sid, CFStringRef name);
//CG_EXTERN CGError CGSSpaceSetAbsoluteLevel(CGSConnectionID cid, CGSSpaceID sid, int level);
//CG_EXTERN void CGSShowSpaces(CGSConnectionID cid, CFArrayRef spaces);
//CG_EXTERN void CGSHideSpaces(CGSConnectionID cid, CFArrayRef spaces);
//CG_EXTERN void CGSAddWindowsToSpaces(CGSConnectionID cid, CFArrayRef windows, CFArrayRef spaces);
//CG_EXTERN void CGSRemoveWindowsFromSpaces(CGSConnectionID cid, CFArrayRef windows, CFArrayRef spaces);

NS_ASSUME_NONNULL_BEGIN
@interface Spaces : NSObject
+ (void) init: (int) cgsMainConnectionId;
+ (int) CGSMainConnectID;
+ (int) currentSpaceId;
+ (int) currentSpaceIndex;
+ (int) indexWithID: (int) ID;
+ (int) IDWithIndex: (int) index;
+ (NSArray<NSNumber* /* CGSSpaceID */>*) spaces;
+ (NSArray<NSNumber* /* CGSSpaceID */>*) visibleSpaces;
+ (NSMutableDictionary<NSString*, NSArray<NSNumber*/* CGSSpaceID */>*>*) screenSpacesMap;
+ (NSArray<NSNumber* /* CGSSpaceID */>*) otherSpaces;
+ (NSArray<NSNumber* /* CGWindowID */>*) windowsInSpaces: (NSArray*) spaces : (BOOL) includeInvisible;
+ (void) refreshCurrentSpaceId;
+ (void) refreshAllIdsAndIndexes;
+ (void) updateCurrentSpace;
+ (NSString*) uuidForScreen: (NSScreen*) screen;
+ (NSScreen*) screenWithDisplayID: (CGDirectDisplayID) displayID;
+ (NSScreen*) cachedPrimaryScreen;
@end
NS_ASSUME_NONNULL_END
