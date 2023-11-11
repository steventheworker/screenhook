//
//  currentSpaceIDScriptCommand.m
//  screenhook
//
//  Created by Steven G on 11/10/23.
//

#import "currentSpaceIDScriptCommand.h"
#import "../../Spaces.h"

@implementation currentSpaceIDScriptCommand
- (id) performDefaultImplementation {
    return @([Spaces currentSpaceId]);
}
@end
