
#import "LRActionVersion.h"
@import PackageManagerKit;


@interface LRActionVersion ()

@end


@implementation LRActionVersion

- (instancetype)initWithType:(Action *)type manifest:(LRActionManifest *)manifest packageSet:(LRPackageSet *)packageSet {
    if (self = [super init]) {
        _type = type;
        _manifest = manifest;
        _packageSet = packageSet;
    }
    return self;
}

- (LRVersion *)primaryVersion {
    LRPackage *package = [_packageSet.packages firstObject];
    return package.version;
}

@end
