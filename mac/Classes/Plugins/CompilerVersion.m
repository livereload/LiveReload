
#import "CompilerVersion.h"


@implementation CompilerVersion

@synthesize name=_name;

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
    }
    return self;
}

- (void)dealloc {
    _name = nil;
}

@end
