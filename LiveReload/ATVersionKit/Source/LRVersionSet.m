
#import "LRVersionSet.h"
#import "LRVersionRange.h"


@interface LRVersionSet ()

- (instancetype)initWithRanges:(NSArray *)ranges error:(NSError *)error;

@end


@implementation LRVersionSet {
    NSArray *_ranges;
}

- (instancetype)initWithRanges:(NSArray *)ranges error:(NSError *)error {
    self = [super init];
    if (self) {
        _ranges = [ranges copy];
        _error = error;
        if (!_error) {
            for (LRVersionRange *range in _ranges) {
                if (range.error) {
                    _error = range.error;
                    break;
                }
            }
        }
    }
    return self;
}

+ (instancetype)versionSetWithRange:(LRVersionRange *)range {
    return [[self alloc] initWithRanges:@[range] error:nil];
}

+ (instancetype)versionSetWithRanges:(NSArray *)ranges {
    return [[self alloc] initWithRanges:ranges error:nil];
}

+ (instancetype)versionSetWithVersion:(LRVersion *)version {
    return [self versionSetWithRange:[LRVersionRange versionRangeWithVersion:version]];
}

+ (instancetype)emptyVersionSet {
    return [[self alloc] initWithRanges:@[] error:nil];
}

+ (instancetype)emptyVersionSetWithError:(NSError *)error {
    return [[self alloc] initWithRanges:@[] error:error];
}

+ (instancetype)allVersionsSet {
    return [self versionSetWithRange:[LRVersionRange unboundedVersionRange]];
}

- (BOOL)containsVersion:(LRVersion *)version {
    if (!self.valid)
        return NO;

    for (LRVersionRange *range in _ranges) {
        if ([range containsVersion:version])
            return YES;
    }
    return NO;
}

- (NSString *)description {
    if (_ranges.count == 0)
        return @"()";
    return [_ranges componentsJoinedByString:@" | "];
}

- (BOOL)isValid {
    return _error == nil;
}

- (LRVersionSpace *)versionSpace {
    return [[_ranges firstObject] versionSpace];
}

@end
