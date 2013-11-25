
#import "LRPackageManager.h"
#import "LRPackageType.h"
#import "LRPackageReference.h"
#import "LRVersionSpace.h"
#import "LRVersionSet.h"


@interface LRPackageManager ()

@end


@implementation LRPackageManager {
    NSMutableArray *_packageTypes;
    NSMutableDictionary *_packageTypesByName;
}

- (id)init {
    self = [super init];
    if (self) {
        _packageTypes = [NSMutableArray new];
        _packageTypesByName = [NSMutableDictionary new];
    }
    return self;
}

- (void)addPackageType:(LRPackageType *)type {
    [_packageTypes addObject:type];
    _packageTypesByName[type.name] = type;
}

- (LRPackageType *)packageTypeNamed:(NSString *)name {
    return _packageTypesByName[name];
}

- (NSArray *)packageTypes {
    return [_packageTypes copy];
}

- (void)addPackageContainer:(LRPackageContainer *)container {

}

- (void)removePackageContainer:(LRPackageContainer *)container {

}

- (LRPackageReference *)packageReferenceWithDictionary:(NSDictionary *)dictionary {
    NSString *typeName = dictionary[@"type"];
    if (!typeName)
        return nil;
    LRPackageType *type = [self packageTypeNamed:typeName];
    if (!type)
        return nil;

    NSString *name = dictionary[@"name"];
    if (!name)
        return nil;

    NSString *versionSpec = dictionary[@"version"];
    LRVersionSet *versionSet = nil;
    if (versionSpec) {
        versionSet = [type.versionSpace versionSetWithString:versionSpec];
        if (!versionSet.valid) {
            NSLog(@"Package '%@' version spec problem: %@", name, versionSet.error.localizedDescription);
        }
    }

    return [[LRPackageReference alloc] initWithType:type name:name versionSpec:versionSet];
}

@end
