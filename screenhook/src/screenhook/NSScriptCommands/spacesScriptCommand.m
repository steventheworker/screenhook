//
//  spacesScriptCommand.m
//  screenhook
//
//  Created by Steven G on 11/10/23.
//

#import "spacesScriptCommand.h"
#import "../../Spaces.h"

@implementation spacesScriptCommand : NSScriptCommand
- (id) performDefaultImplementation {
    NSMutableArray* res = [NSMutableArray array];
    for (NSArray* spaceInfo in [Spaces spaces]) {
        [res addObject: spaceInfo[1]];
    }
    return res;
}
@end
