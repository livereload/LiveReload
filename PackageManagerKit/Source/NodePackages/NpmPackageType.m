
#import "NpmPackageType.h"
#import "NpmPackageContainer.h"
@import ATVersionKit;


@implementation NpmPackageType

- (NSString *)name {
    return @"npm";
}

- (LRVersionSpace *)versionSpace {
    return [LRSemanticVersionSpace semanticVersionSpace];
}

- (LRPackageContainer *)packageContainerAtFolderURL:(NSURL *)folderURL {
    return [[NpmPackageContainer alloc] initWithPackageType:self folderURL:folderURL];
}

@end
