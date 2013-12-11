
#import "LRTestOutputFile.h"


#define return_error(returnValue, outError, error)  do { \
        if (outError) *outError = error; \
        return returnValue; \
    } while(0)


@interface LRTestOutputFile ()

@end


@implementation LRTestOutputFile

- (id)initWithRelativePath:(NSString *)relativePath absoluteURL:(NSURL *)absoluteURL expectation:(id)expectation {
    self = [super init];
    if (self) {
        _relativePath = [relativePath copy];
        _absoluteURL = absoluteURL;

        if ([expectation isKindOfClass:NSString.class])
            _expectedContent = [expectation copy];
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
    if (_expectedContent.length > 0) {
        if (NSNotFound == [actualContent rangeOfString:_expectedContent].location) {
            return_error(NO, outError, ([NSError errorWithDomain:@"com.livereload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Expected content not found in: %@", _relativePath]}]));
        }
    }
    return YES;
}

@end
