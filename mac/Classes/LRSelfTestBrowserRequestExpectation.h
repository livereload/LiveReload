
#import <Foundation/Foundation.h>


@interface LRSelfTestBrowserRequestExpectation : NSObject

- (instancetype)initWithExpectationData:(id)expectation;
- (BOOL)matchesRequest:(NSDictionary *)request;

@end
