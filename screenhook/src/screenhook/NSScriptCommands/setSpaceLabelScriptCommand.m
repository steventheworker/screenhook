//
//  setSpaceLabelScriptCommand.m
//  screenhook
//
//  Created by Steven G on 12/7/23.
//

#import "setSpaceLabelScriptCommand.h"
#import "../missionControlSpaceLabels.h"

@implementation setSpaceLabelScriptCommand
- (id) performDefaultImplementation {
    NSDictionary* args = self.evaluatedArguments;
    if (!args.count) {
        [self setScriptErrorNumber: -50]; // raise error
        [self setScriptErrorString: @"Parameter Error: A Parameter is expected for the verb 'updateFFSidebarShowing' (You have to specify if the sidebar is showing! (hint: boolean))."];
        return nil;
    }
    int spaceindex = [[args valueForKey: @""] intValue]; // get the direct argument
    NSString* label = [args valueForKey:@"label"];
    [missionControlSpaceLabels setLabel: spaceindex : label];
    return nil;
}
@end
