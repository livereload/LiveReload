
#import <Foundation/Foundation.h>


@interface LRTestOutputExpectation : NSObject

- (id)initWithExpectationData:(id)expectation;

@property(nonatomic, readonly) NSString *content;

- (BOOL)validateWithContent:(NSString *)content;

@end
