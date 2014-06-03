
#import <Foundation/Foundation.h>


@interface LRSelfTestOutputFile : NSObject

- (id)initWithRelativePath:(NSString *)relativePath absoluteURL:(NSURL *)absoluteURL expectation:(id)expectation;

@property(nonatomic, readonly) NSString *relativePath;
@property(nonatomic, readonly) NSURL *absoluteURL;

- (void)removeOutputFile;
- (BOOL)verifyExpectationsWithError:(NSError **)error;

@end
