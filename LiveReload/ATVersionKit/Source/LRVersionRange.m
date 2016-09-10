
#import "LRVersionRange.h"
#import "LRVersion.h"


@interface LRVersionRange ()

@end


@implementation LRVersionRange

- (instancetype)initWithStartingVersion:(LRVersion *)startingVersion startIncluded:(BOOL)startIncluded endingVersion:(LRVersion *)endingVersion endIncluded:(BOOL)endIncluded {
    NSParameterAssert(startingVersion.versionSpace == endingVersion.versionSpace);

    self = [super init];
    if (self) {
        _startingVersion = startingVersion;
        _endingVersion = endingVersion;

        _startIncluded = startIncluded;
        _endIncluded = endIncluded;

        _error = startingVersion.error ?: endingVersion.error;
    }
    return self;
}

+ (instancetype)versionRangeWithVersion:(LRVersion *)version {
    return [[self alloc] initWithStartingVersion:version startIncluded:YES endingVersion:version endIncluded:YES];
}

+ (instancetype)unboundedVersionRange {
    return [[self alloc] initWithStartingVersion:nil startIncluded:YES endingVersion:nil endIncluded:YES];
}

- (BOOL)containsVersion:(LRVersion *)version {
    if (_startingVersion)
        NSParameterAssert(version.versionSpace == _startingVersion.versionSpace);
    if (_endingVersion)
        NSParameterAssert(version.versionSpace == _endingVersion.versionSpace);

    if (!self.valid)
        return NO;

    if (_startingVersion) {
        NSComparisonResult c = [_startingVersion compare:version];
        if (c == NSOrderedDescending)
            return NO;
        if (c == NSOrderedSame && !_startIncluded)
            return NO;
    }

    if (_endingVersion) {
        NSComparisonResult c = [_endingVersion compare:version];
        if (c == NSOrderedAscending)
            return NO;
        if (c == NSOrderedSame && !_endIncluded)
            return NO;
    }

    return YES;
}

- (NSString *)description {
    if (!_startingVersion && !_endingVersion)
        return @"*";

    if (_startIncluded && _endIncluded && [_startingVersion isEqual:_endingVersion])
        return [NSString stringWithFormat:@"=%@", _startingVersion];

    NSMutableString *result = [NSMutableString new];
    if (_startingVersion) {
        if (_startIncluded)
            [result appendString:@">="];
        else
            [result appendString:@">"];
        [result appendString:[_startingVersion description]];
    }
    if (_startingVersion && _endingVersion)
        [result appendString:@" "];
    if (_endingVersion) {
        if (_endIncluded)
            [result appendString:@"<="];
        else
            [result appendString:@"<"];
        [result appendString:[_endingVersion description]];
    }
    return [result copy];
}

- (BOOL)isValid {
    return _error == nil;
}

- (LRVersionSpace *)versionSpace {
    return _startingVersion.versionSpace ?: _endingVersion.versionSpace;
}

@end
