
#import "FSTreeFilter.h"


@implementation FSTreeFilter

@synthesize enabledExtensions=_enabledExtensions;

- (void)dealloc {
    [_enabledExtensions release], _enabledExtensions = nil;
    [super dealloc];
}


#pragma mark - Filtering

- (BOOL)acceptsFileName:(NSString *)name {
    if (_enabledExtensions) {
        NSString *extension = [name pathExtension];
        if (![_enabledExtensions containsObject:extension]) {
            return NO;
        }
    }
    return YES;
}

@end
