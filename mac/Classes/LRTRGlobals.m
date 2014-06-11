
#import "LRTRGlobals.h"

NSString *LRTRTestStatusDescription(LRTRTestStatus status) {
    switch (status) {
        case LRTRTestStatusNone:
            return @"none";
        case LRTRTestStatusSucceeded:
            return @"succeeded";
        case LRTRTestStatusFailed:
            return @"failed";
        case LRTRTestStatusSkipped:
            return @"skipped";
        case LRTRTestStatusRunning:
            return @"running";
        default:
            NSCAssert(NO, @"Unknown test status %d", (int)status);
            return nil;
    }
}
