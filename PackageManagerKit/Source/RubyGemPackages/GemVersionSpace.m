
#import "GemVersionSpace.h"
#import "GemVersion.h"


@interface GemVersionSpace ()

@end


@implementation GemVersionSpace

+ (instancetype)gemVersionSpace {
    static GemVersionSpace *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [GemVersionSpace new];
    });
    return instance;
}

- (LRVersion *)versionWithString:(NSString *)string {
    return [GemVersion gemVersionWithString:string];
}

- (LRVersion *)versionWithMajor:(NSInteger)major minor:(NSInteger)minor {
    return [GemVersion gemVersionWithSegments:@[@(major), @(minor)]];
}

@end
