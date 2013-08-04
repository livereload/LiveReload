
#import "ATHash.h"
#import <CommonCrypto/CommonDigest.h>

NSString *ATComputeMD5HashOfFile(NSString *path) {
    unsigned char outputData[CC_MD5_DIGEST_LENGTH];

    NSData *inputData = [[NSData alloc] initWithContentsOfFile:path];
    CC_MD5([inputData bytes], [inputData length], outputData);
    [inputData release];

    NSMutableString *hash = [[NSMutableString alloc] init];

    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", outputData[i]];
    }

    return hash;
}
