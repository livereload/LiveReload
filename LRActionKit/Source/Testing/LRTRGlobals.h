@import Foundation;

typedef enum : NSUInteger {
    LRTRTestStatusNone,
    LRTRTestStatusRunning,
    LRTRTestStatusSucceeded,
    LRTRTestStatusFailed,
    LRTRTestStatusSkipped
} LRTRTestStatus;

NSString *LRTRTestStatusDescription(LRTRTestStatus status);
