
#import "LRSemanticVersionSpace.h"
#import "LRSemanticVersion.h"


@implementation LRSemanticVersionSpace

+ (instancetype)semanticVersionSpace {
    static LRSemanticVersionSpace *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [LRSemanticVersionSpace new];
    });
    return instance;
}

- (LRVersion *)versionWithString:(NSString *)string {
    return [LRSemanticVersion semanticVersionWithString:string];
}

- (LRVersion *)versionWithMajor:(NSInteger)major minor:(NSInteger)minor {
    return [[LRSemanticVersion alloc] initWithMajor:major minor:minor patch:0 prereleaseComponents:@[] build:@"" error:nil];
}

@end
