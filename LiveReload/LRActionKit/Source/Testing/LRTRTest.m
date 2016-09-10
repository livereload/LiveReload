
#import "LRTRTest.h"


@interface LRTRTest ()

@end


@implementation LRTRTest {
    NSMutableString *_extraOutput;
}

- (instancetype)initWithName:(NSString *)name status:(LRTRTestStatus)status {
    self = [super init];
    if (self) {
        _name = [name copy];
        _status = status;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"[%@] %@", LRTRTestStatusDescription(_status), _name];
}

- (void)appendExtraOutput:(NSString *)output {
    [_extraOutput appendString:output];
}

@end
