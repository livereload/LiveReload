
#import "MASReceipt.h"

#import <CommonCrypto/CommonDigest.h>


static __used NSString *SHA1OfNSDataAsNSString(NSData *data) {
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return output;
}


static NSString *MASReceiptStashedReceiptsFolder(BOOL create) {
    NSString *stashedReceiptsFolder = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:MASReceiptApplicationSupportReceiptsFolder];
    if (create) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:stashedReceiptsFolder]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:stashedReceiptsFolder withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }
    return stashedReceiptsFolder;
}


void MASReceiptStartup() {
#ifdef APPSTORE
    NSString *receiptPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/_MASReceipt/receipt"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:receiptPath]) {
        // magic return value to make Finder ask for an App Store account and create a receipt
        exit(173);
    }
    
    NSData *receipt = [NSData dataWithContentsOfFile:receiptPath];
    NSString *receiptHash = SHA1OfNSDataAsNSString(receipt);
    
    NSString *stashedReceiptFile = [MASReceiptStashedReceiptsFolder(YES) stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", receiptHash, MASReceiptFileExtension]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:stashedReceiptFile]) {
        [[NSFileManager defaultManager] copyItemAtPath:receiptPath toPath:stashedReceiptFile error:NULL];
    }
#endif
}


BOOL MASReceiptIsAuthenticated() {
#ifdef APPSTORE
    return YES;
#else
    NSString *stashedReceiptsFolder = MASReceiptStashedReceiptsFolder(NO);
    for (NSString *fileName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:stashedReceiptsFolder error:NULL]) {
        if ([[fileName pathExtension] isEqualToString:MASReceiptFileExtension]) {
            return YES;
        }
    }
    return NO;
#endif
}
