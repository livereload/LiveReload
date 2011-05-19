
#import "VersionNumber.h"

VersionNumber VersionNumberFromNSString(NSString *string) {
    NSArray *components = [string componentsSeparatedByString:@"."];
    VersionNumber result = 10000 * [[components objectAtIndex:0] intValue];
    if ([components count] > 1) {
        result += 100 * [[components objectAtIndex:1] intValue];
    }
    if ([components count] > 2) {
        result += [[components objectAtIndex:2] intValue];
    }
    return result;
}
