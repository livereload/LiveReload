@import LRCommons;

#import "LRSelfTestOutputFile.h"
#import "LRSelfTestOutputExpectation.h"


#define return_error(returnValue, outError, error)  do { \
        if (outError) *outError = error; \
        return returnValue; \
    } while(0)


@interface LRSelfTestOutputFile ()

@property(nonatomic, readonly) NSArray *expectations;
@property(nonatomic, readonly) BOOL binary;
@property(nonatomic, readonly) long long minSize;

@end


@implementation LRSelfTestOutputFile

- (id)initWithRelativePath:(NSString *)relativePath absoluteURL:(NSURL *)absoluteURL expectation:(id)expectationRaw {
    self = [super init];
    if (self) {
        _relativePath = [relativePath copy];
        _absoluteURL = absoluteURL;

        NSArray *expectations;
        if ([expectationRaw isKindOfClass:NSNumber.class]) {
            expectations = @[];
        } else if ([expectationRaw isKindOfClass:NSArray.class]) {
            expectations = expectationRaw;
        } else if ([expectationRaw isKindOfClass:NSString.class]) {
            expectations = @[expectationRaw];
        } else if ([expectationRaw isKindOfClass:NSDictionary.class]) {
            NSDictionary *expectationDictionary = expectationRaw;
            _binary = [expectationDictionary[@"binary"] boolValue];
            _expectations = expectationDictionary[@"strings"] ?: @[];
            _minSize = [expectationDictionary[@"minSize"] longLongValue];
        } else {
            NSAssert(NO, @"Unknown expectation type: %@", expectationRaw);
            abort();
        }

        _expectations = [expectations arrayByMappingElementsUsingBlock:^id(id expectation) {
            return [[LRSelfTestOutputExpectation alloc] initWithExpectationData:expectation];
        }];
    }
    return self;
}

- (void)removeOutputFile {
    [[NSFileManager defaultManager] removeItemAtURL:_absoluteURL error:NULL];
}

- (BOOL)verifyExpectationsWithError:(NSError **)outError {
    NSDictionary *properties = [_absoluteURL resourceValuesForKeys:@[NSURLFileSizeKey] error:NULL];
    if (!properties) {
        return_error(NO, outError, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Output file not found: %@", _relativePath]}]));
    }

    if (_minSize > 0) {
        long long size = [properties[NSURLFileSizeKey] longLongValue];
        if (size < _minSize) {
            if (size == 0) {
                return_error(NO, outError, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"File is empty: %@", _relativePath]}]));
            } else {
                return_error(NO, outError, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"File too small (%lld < %lld): %@", size, _minSize, _relativePath]}]));
            }
        }
    }

    if (_binary) {
        NSAssert(_expectations.count == 0, @"Content expectations not supported for binary files");
        return YES;
    }

    NSString *actualContent = [NSString stringWithContentsOfURL:_absoluteURL encoding:NSUTF8StringEncoding error:NULL];
    if (!actualContent)
        return_error(NO, outError, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Failed to read output file %@", _relativePath]}]));
    for (LRSelfTestOutputExpectation *expectation in _expectations) {
        if (![expectation validateWithContent:actualContent]) {
            return_error(NO, outError, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ failed to meet expectation: %@", _relativePath, expectation]}]));
        }
    }
    return YES;
}

@end
