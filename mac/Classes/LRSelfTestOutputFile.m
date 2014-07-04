
#import "LRSelfTestOutputFile.h"
#import "LRSelfTestOutputExpectation.h"

#import "ATFunctionalStyle.h"


#define return_error(returnValue, outError, error)  do { \
        if (outError) *outError = error; \
        return returnValue; \
    } while(0)


@interface LRSelfTestOutputFile ()

@property(nonatomic, readonly) NSArray *expectations;

@end


@implementation LRSelfTestOutputFile

- (id)initWithRelativePath:(NSString *)relativePath absoluteURL:(NSURL *)absoluteURL expectation:(id)expectations {
    self = [super init];
    if (self) {
        _relativePath = [relativePath copy];
        _absoluteURL = absoluteURL;

        if (![expectations isKindOfClass:NSArray.class])
            expectations = @[expectations];

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
    NSString *actualContent = [NSString stringWithContentsOfURL:_absoluteURL encoding:NSUTF8StringEncoding error:NULL];
    if (!actualContent)
        return_error(NO, outError, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Output file not found: %@", _relativePath]}]));
    for (LRSelfTestOutputExpectation *expectation in _expectations) {
        if (![expectation validateWithContent:actualContent]) {
            return_error(NO, outError, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ failed to meet expectation: %@", _relativePath, expectation]}]));
        }
    }
    return YES;
}

@end
