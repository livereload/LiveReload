
#import "MD5OfFile.h"
#import <CommonCrypto/CommonDigest.h>

NSString* MD5OfFile(NSString *pathToFile) {
    unsigned char outputData[CC_MD5_DIGEST_LENGTH];

    NSData *inputData = [[NSData alloc] initWithContentsOfFile:pathToFile];
    CC_MD5([inputData bytes], [inputData length], outputData);
    [inputData release];

    NSMutableString *hash = [[NSMutableString alloc] init];

    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", outputData[i]];
    }

    return hash;
}
