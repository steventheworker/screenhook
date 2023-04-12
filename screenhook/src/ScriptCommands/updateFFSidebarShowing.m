//
//  updateFFSidebarShowing.m
//  screenhook
//
//  Created by Steven G on 4/11/23.
//

#import "updateFFSidebarShowing.h"
#import "timer.h"

@implementation updateFFSidebarShowing
- (id) performDefaultImplementation {
    NSDictionary *args = [self evaluatedArguments];
    BOOL val = nil;
    if (args.count) {
        val = [[args valueForKey:@""] boolValue];    // get the direct argument
    } else {
        [self setScriptErrorNumber:-50]; // raise error
        [self setScriptErrorString:@"Parameter Error: A Parameter is expected for the verb 'updateFFSidebarShowing' (You have to specify if the sidebar is showing! (hint: boolean))."];
    }
    [timer updateFFSidebarShowing: val];
    NSLog(@"%d", val);
    return nil;
}
@end
