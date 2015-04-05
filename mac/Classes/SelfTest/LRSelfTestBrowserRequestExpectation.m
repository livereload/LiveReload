
#import "LRSelfTestBrowserRequestExpectation.h"


@interface LRSelfTestBrowserRequestExpectation ()

@end


@implementation LRSelfTestBrowserRequestExpectation {
    id _raw;
    NSString *_path;
    NSString *_localPath;
    NSString *_originalPath;
}

- (instancetype)initWithExpectationData:(id)expectation {
    self = [super init];
    if (self) {
        if ([expectation isKindOfClass:NSDictionary.class]) {
            NSDictionary *data = expectation;
            _path = [self stringFromStringOrNull:data[@"path"]];
            _localPath = [self stringFromStringOrNull:data[@"localPath"]];
            _originalPath = [self stringFromStringOrNull:data[@"originalPath"]];
            _raw = [expectation copy];
        }
    }
    return self;
}

- (NSString *)description {
    return [_raw description];
}

- (NSString *)stringFromStringOrNull:(id)value {
    if ([value isKindOfClass:NSString.class])
        return [value copy];
    else if (value == [NSNull null])
        return nil;
    else {
        NSAssert(NO, @"Expected string or null: %@", value);
        return nil;
    }
}

- (BOOL)expectedPath:(NSString *)expectedPath matchesActualPath:(id)actualPath {
    if (actualPath == [NSNull null])
        actualPath = nil;

    if (expectedPath == nil) {
        return (actualPath == nil);
    } else {
        if (actualPath == nil)
            return NO;

        // TODO: compare all path components from expectedPath

        return [[expectedPath lastPathComponent] isEqualToString:[actualPath lastPathComponent]];
    }
}

- (BOOL)matchesRequest:(NSDictionary *)request {
    return [self expectedPath:_path matchesActualPath:request[@"path"]]
        && [self expectedPath:_localPath matchesActualPath:request[@"localPath"]]
        && [self expectedPath:_originalPath matchesActualPath:request[@"originalPath"]];
}


@end
