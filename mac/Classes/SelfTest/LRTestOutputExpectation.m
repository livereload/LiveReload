
#import "LRTestOutputExpectation.h"


@interface LRTestOutputExpectation ()

@end


@implementation LRTestOutputExpectation

- (id)initWithExpectationData:(id)expectation {
    self = [super init];
    if (self) {
        if ([expectation isKindOfClass:NSString.class])
            _content = [expectation copy];
    }
    return self;
}

- (BOOL)validateWithContent:(NSString *)content {
    return _content.length == 0 || NSNotFound != [content rangeOfString:_content].location;
}

- (NSString *)description {
    if (_content.length > 0)
        return [NSString stringWithFormat:@"contains: %@", _content];
    else
        return @"exists";
}

@end
