
#import "LRTRRun.h"
#import "LRTRTest.h"


@interface LRTRRun ()

@end


@implementation LRTRRun {
    NSMutableArray *_tests;
    LRTRTest *_recentTest;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tests = [NSMutableArray new];
    }
    return self;
}

- (void)finishedTestNamed:(NSString *)name withStatus:(LRTRTestStatus)status {
    LRTRTest *test = [[LRTRTest alloc] initWithName:name status:status];
    [_tests addObject:test];
    _recentTest = test;
}

- (void)appendExtraOutput:(NSString *)output {
    [_recentTest appendExtraOutput:output];
}

@end
