
#import "Project.h"


@implementation Project

@synthesize path=_path;


#pragma mark -
#pragma mark Init/dealloc

- (id)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _path = [path copy];
    }
    return self;
}

- (void)dealloc {
    [_path release], _path = nil;
    [super dealloc];
}

@end
