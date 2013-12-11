
#import <Foundation/Foundation.h>


@interface LRTestOutputFile : NSObject

- (id)initWithRelativePath:(NSString *)relativePath absoluteURL:(NSURL *)absoluteURL expectation:(id)expectation;

@property(nonatomic, readonly) NSString *relativePath;
@property(nonatomic, readonly) NSURL *absoluteURL;
@property(nonatomic, readonly) NSString *expectedContent;

- (void)removeOutputFile;
- (BOOL)verifyExpectationsWithError:(NSError **)error;

@end
