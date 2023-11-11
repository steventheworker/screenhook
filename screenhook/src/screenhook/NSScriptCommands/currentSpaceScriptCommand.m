//
//  currentSpaceScriptCommand.m
//  screenhook
//
//  Created by Steven G on 11/10/23.
//

#import "currentSpaceScriptCommand.h"
#import "../../Spaces.h"

@implementation currentSpaceScriptCommand : NSScriptCommand
- (id) performDefaultImplementation {
    return @([Spaces currentSpaceIndex]);
}
@end
