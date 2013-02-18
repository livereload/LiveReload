
#include "nodeapp.h"
#include "nodeapp_licensing.h"

#import <CommonCrypto/CommonDigest.h>


#ifdef APPSTORE
static NSString *SHA1OfNSDataAsNSString(NSData *data) {
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return output;
}
#endif


static NSString *MASReceiptStashedReceiptsFolder(BOOL create) {
    NSString *stashedReceiptsFolder = [NSStr(nodeapp_appdata_dir) stringByAppendingPathComponent:@"" NODEAPP_LICENSING_SAVED_RECEIPTS_FOLDER];
    if (create) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:stashedReceiptsFolder]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:stashedReceiptsFolder withIntermediateDirectories:YES attributes:nil error:NULL];
        }
    }
    return stashedReceiptsFolder;
}


bool nodeapp_licensing_verify_receipt() {
#ifdef APPSTORE
    return YES;
#else
    NSString *stashedReceiptsFolder = MASReceiptStashedReceiptsFolder(NO);
    for (NSString *fileName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:stashedReceiptsFolder error:NULL]) {
        if ([[fileName pathExtension] isEqualToString:@"" NODEAPP_LICENSING_SAVED_RECEIPTS_EXT]) {
            return YES;
        }
    }
    return NO;
#endif
}

void nodeapp_licensing_startup() {
#ifdef APPSTORE
    NSString *receiptPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/_MASReceipt/receipt"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:receiptPath]) {
        // magic return value to make Finder ask for an App Store account and create a receipt
        exit(173);
    }

    NSData *receipt = [NSData dataWithContentsOfFile:receiptPath];
    NSString *receiptHash = SHA1OfNSDataAsNSString(receipt);

    NSString *stashedReceiptFile = [MASReceiptStashedReceiptsFolder(YES) stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", receiptHash, @"" NODEAPP_LICENSING_SAVED_RECEIPTS_EXT]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:stashedReceiptFile]) {
        [[NSFileManager defaultManager] copyItemAtPath:receiptPath toPath:stashedReceiptFile error:NULL];
    }
#endif
}

json_t *C_licensing__verify_receipt(json_t *arg) {
    return json_bool(nodeapp_licensing_verify_receipt());
}
