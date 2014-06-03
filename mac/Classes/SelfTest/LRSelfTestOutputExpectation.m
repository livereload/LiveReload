
#import "LRSelfTestOutputExpectation.h"


@interface LRSelfTestOutputExpectation ()

@end


@implementation LRSelfTestOutputExpectation

- (id)initWithExpectationData:(id)expectation {
    self = [super init];
    if (self) {
        if ([expectation isKindOfClass:NSString.class]) {
            _content = [expectation copy];
            if ([_content hasPrefix:@"!"]) {
                _content = [_content substringFromIndex:1];
                _negated = YES;
            }
        }
    }
    return self;
}

- (BOOL)validateWithContent:(NSString *)content {
    return _content.length == 0 || (_negated == (NSNotFound == [content rangeOfString:_content].location));
}

- (NSString *)description {
    if (_content.length > 0)
        if (_negated)
            return [NSString stringWithFormat:@"does not contain: %@", _content];
        else
            return [NSString stringWithFormat:@"contains: %@", _content];
    else
        return @"exists";
}

@end
