
#import "LRPackageType.h"
#import "LRPackageContainer.h"


@implementation LRPackageType {
    NSMutableArray *_containers;
}

- (id)init {
    if (self = [super init]) {
        _containers = [NSMutableArray new];
    }
    return self;
}

- (NSString *)name {
    abort();
}

- (LRVersionSpace *)versionSpace {
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

- (NSString *)identifierOfPackageNamed:(NSString *)packageName {
    return [NSString stringWithFormat:@"%@:%@", self.name, packageName];
}

@end
