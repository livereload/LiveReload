
#import "LRManifestBasedObject.h"


@interface LRManifestBasedObject ()

@end


@implementation LRManifestBasedObject

- (instancetype)initWithManifest:(NSDictionary *)manifest {
    self = [super init];
    if (self) {
        _manifest = [manifest copy];
    }
    return self;
}

@end
