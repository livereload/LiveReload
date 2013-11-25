
#import "LRPackageSet.h"
#import "LRPackage.h"
#import "LRPackageReference.h"
#import "LRPackageType.h"


@implementation LRPackageSet {
    NSDictionary *_packagesByIdentifier;
}

- (instancetype)initWithPackages:(NSArray *)packages {
    if (self = [super init]) {
        _packages = [packages copy];

        NSMutableDictionary *packagesByIdentifier = [NSMutableDictionary new];
        for (LRPackage *package in _packages) {
            if (packagesByIdentifier[package.identifier] != nil)
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Multiple package versions inside LRPackageSet" userInfo:@{}];
            packagesByIdentifier[package.identifier] = package;
        }
        _packagesByIdentifier = [packagesByIdentifier copy];
    }
    return self;
}

- (LRPackage *)packageNamed:(NSString *)name type:(LRPackageType *)type {
    NSString *identifier = [type identifierOfPackageNamed:name];
    return _packagesByIdentifier[identifier];
}

- (LRPackage *)packageMatchingReference:(LRPackageReference *)reference {
    LRPackage *package = [self packageNamed:reference.name type:reference.type];
    if ([reference matchesPackage:package])
        return package;
    else
        return nil;
}

- (BOOL)matchesAllPackageReferencesInArray:(NSArray *)packageReferences {
    for (LRPackageReference *reference in packageReferences) {
        if (![self packageMatchingReference:reference]) {
            return NO;
        }
    }
    return YES;
}

@end
