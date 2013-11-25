
#import "LRActionVersion.h"


@interface LRActionVersion ()

@end


@implementation LRActionVersion

- (instancetype)initWithType:(ActionType *)type manifest:(LRActionManifest *)manifest packageSet:(LRPackageSet *)packageSet {
    if (self = [super init]) {
        _type = type;
        _manifest = manifest;
        _packageSet = packageSet;
    }
    return self;
}

@end
