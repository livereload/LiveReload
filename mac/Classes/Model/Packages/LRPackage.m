
#import "LRPackage.h"


@interface LRPackage ()

@end


@implementation LRPackage

- (instancetype)initWithName:(NSString *)name version:(LRVersion *)version container:(LRPackageContainer *)container sourceFolderURL:(NSURL *)sourceFolderURL {
    self = [super init];
    if (self) {
        _name = [name copy];
        _version = version;
        _container = container;
        _sourceFolderURL = sourceFolderURL;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@(%@ %@)", NSStringFromClass(self.class), _name, _version];
}

@end
