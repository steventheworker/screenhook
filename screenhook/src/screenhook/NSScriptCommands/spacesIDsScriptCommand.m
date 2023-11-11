//
//  spacesIDsScriptCommand.m
//  screenhook
//
//  Created by Steven G on 11/10/23.
//

#import "spacesIDsScriptCommand.h"
#import "../../Spaces.h"

@implementation spacesIDsScriptCommand
- (id) performDefaultImplementation {
    NSMutableArray* res = [NSMutableArray array];
    for (NSArray* spaceInfo in [Spaces spaces]) {
        [res addObject: spaceInfo[0]];
    }
    return res;
}
@end
