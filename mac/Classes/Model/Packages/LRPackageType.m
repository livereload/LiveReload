
#import "LRPackageType.h"
#import "LRPackageContainer.h"


@implementation LRPackageType {
    NSMutableArray *_containers;
}

- (NSString *)name {
    abort();
}

- (NSString *)bundledPackagesFolderName {
    return self.name;
}

- (void)addPackageContainer:(LRPackageContainer *)container {
    [_containers addObject:container];
    [container startTrackingPackages];
}

- (void)removePackageContainer:(LRPackageContainer *)container {
    [_containers removeObject:container];
    [container endTrackingPackages];
}

- (LRPackageContainer *)packageContainerAtFolderURL:(NSURL *)folderURL {
    return nil;
}

@end
