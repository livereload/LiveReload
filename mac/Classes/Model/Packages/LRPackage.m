
#import "LRPackage.h"
#import "LRPackageContainer.h"
#import "LRPackageType.h"


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
        _identifier = [_container.packageType identifierOfPackageNamed:_name];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@(%@ %@)", NSStringFromClass(self.class), _name, _version];
}

@end
