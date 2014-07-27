
#import "LRPackageReference.h"
#import "LRPackageType.h"
#import "LRPackage.h"
@import PiiVersionKit;


@interface LRPackageReference ()

@end


@implementation LRPackageReference

- (instancetype)initWithType:(LRPackageType *)type name:(NSString *)name versionSpec:(LRVersionSet *)versionSet {
    self = [super init];
    if (self) {
        _type = type;
        _name = [name copy];
        _versionSpec = versionSet ?: [LRVersionSet allVersionsSet];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:%@@%@", _type.name, _name, [_versionSpec description]];
}

- (BOOL)matchesPackage:(LRPackage *)package {
    return [_name isEqualToString:package.name] && [_versionSpec containsVersion:package.version];
}

@end
