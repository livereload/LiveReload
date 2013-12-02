
#import "GemPackageType.h"
#import "GemPackageContainer.h"
#import "GemVersionSpace.h"


@interface GemPackageType ()

@end


@implementation GemPackageType

- (NSString *)name {
    return @"gem";
}

- (LRVersionSpace *)versionSpace {
    return [GemVersionSpace gemVersionSpace];
}

- (LRPackageContainer *)packageContainerAtFolderURL:(NSURL *)folderURL {
    return [[GemPackageContainer alloc] initWithPackageType:self folderURL:folderURL];
}

@end
