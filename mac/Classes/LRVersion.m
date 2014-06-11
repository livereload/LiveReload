
#import "LRVersion.h"


NSString *const LRVersionErrorDomain = @"LRVersionErrorDomain";


@implementation LRVersion

- (id)initWithVersionSpace:(LRVersionSpace *)versionSpace error:(NSError *)error {
    self = [super init];
    if (self) {
        _versionSpace = versionSpace;
        _error = error;
    }
    return self;
}

- (BOOL)isValid {
    return _error == nil;
}

- (NSInteger)major {
    abort();
}

- (NSInteger)minor {
    abort();
}

- (NSComparisonResult)compare:(LRVersion *)aVersion {
    abort();
}

- (BOOL)isEqual:(id)object {
    return [object class] == [self class] && [self compare:object] == NSOrderedSame;
}

@end
