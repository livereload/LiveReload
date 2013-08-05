
#import "ATJson.h"

NSString *ATJsonErrorDomain = @"ATJsonErrorDomain";

#define return_error(returnValue, outError, error)  do { \
        if (outError) *outError = error; \
        return nil; \
    } while(0)


@implementation NSDictionary (LRPluginCommons)

+ (NSDictionary *)LR_dictionaryWithContentsOfJSONFileURL:(NSURL *)fileURL error:(NSError **)outError {
    NSError *error = nil;
    NSData *raw = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
    if (!raw)
        return_error(nil, outError, error);

    id object = [NSJSONSerialization JSONObjectWithData:raw options:0 error:&error];
    if (!object)
        return_error(nil, outError, error);

    if (![object isKindOfClass:[NSDictionary class]])
        return_error(nil, outError, [NSError errorWithDomain:ATJsonErrorDomain code:ATJsonErrorCodeInvalidRootObject userInfo:nil]);

    return object;
}

@end
