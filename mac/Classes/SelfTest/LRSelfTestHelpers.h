
#import <Foundation/Foundation.h>


BOOL LRSelfTestMatchPath(NSString *pattern, NSString *path);
BOOL LRSelfTestMatchUnsignedInteger(NSInteger pattern, NSUInteger value);
BOOL LRSelfTestMatchString(NSString *pattern, NSString *value);

typedef BOOL (^LRSelfTestMatchUnorderedArraysMatchBlock)(id expectation, id value);
BOOL LRSelfTestMatchUnorderedArrays(NSArray *expectations, NSArray *values, NSString *errorMessage, NSError **outError, LRSelfTestMatchUnorderedArraysMatchBlock matchBlock);
