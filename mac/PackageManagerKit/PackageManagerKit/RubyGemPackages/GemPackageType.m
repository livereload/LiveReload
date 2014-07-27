
#import "GemPackageType.h"
#import "GemPackageContainer.h"
#import "GemVersionSpace.h"

#import "RuntimeInstance.h"

@import LRCommons;


@interface GemPackageType ()

@end


@implementation GemPackageType

- (id)init {
    self = [super init];
    if (self) {
        [self observeNotification:LRRuntimeInstanceDidChangeNotification withSelector:@selector(runtimeInstanceDidChange:)];
    }
    return self;
}

- (NSString *)name {
    return @"gem";
}

- (LRVersionSpace *)versionSpace {
    return [GemVersionSpace gemVersionSpace];
}

- (LRPackageContainer *)packageContainerAtFolderURL:(NSURL *)folderURL {
    return [[GemPackageContainer alloc] initWithPackageType:self folderURL:folderURL];
}

- (void)runtimeInstanceDidChange:(NSNotification *)notification {
    RuntimeInstance *instance = notification.object;
    for (LRPackageContainer *container in [self.containers copy]) {
        if (container.runtimeInstance == instance) {
            [self removePackageContainer:container];
        }
    }
    for (LRPackageContainer *container in instance.defaultPackageContainers) {
        [self addPackageContainer:container];
    }
}

@end
