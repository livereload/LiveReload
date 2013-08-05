
#import <Foundation/Foundation.h>

extern NSString *ATJsonErrorDomain;

typedef enum {
    ATJsonErrorCodeInvalidRootObject = 1,
} ATJsonErrorCode;

@interface NSDictionary (ATJson)
+ (NSDictionary *)LR_dictionaryWithContentsOfJSONFileURL:(NSURL *)fileURL error:(NSError **)error;
@end
