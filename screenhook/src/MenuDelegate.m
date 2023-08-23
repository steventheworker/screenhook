//
//  MenuDelegate.m
//  screenhook
//
//  Created by Steven G on 8/22/23.
//

#import "MenuDelegate.h"
#import "app.h"

//clicking menu bar icon with kCGEventTapOptionDefault (modifying events) stops working if you click the menubar icon
//this releases the old listeners, and adds new ones when the menu closes
@implementation MenuDelegate
- (void)menuWillOpen:(NSMenu *)menu {
    [app stopListening];
}
- (void)menuDidClose:(NSMenu *)menu {
    [app startListening];
}
@end
