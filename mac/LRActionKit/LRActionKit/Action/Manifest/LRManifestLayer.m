@import LRCommons;
@import PackageManagerKit;

#import "LRManifestLayer.h"
#import "LRManifestErrorSink.h"
#import "ActionKitSingleton.h"


@interface LRManifestLayer ()

@end


@implementation LRManifestLayer

- (instancetype)initWithManifest:(NSDictionary *)manifest errorSink:(id<LRManifestErrorSink>)errorSink {
    return [self initWithManifest:manifest requiredPackageReferences:[LRManifestLayer packageReferencesWithManifest:manifest] errorSink:errorSink];
}

- (instancetype)initWithManifest:(NSDictionary *)manifest requiredPackageReferences:(NSArray *)requiredPackageReferences errorSink:(id<LRManifestErrorSink>)errorSink {
    self = [super initWithManifest:manifest errorSink:errorSink];
    if (self) {
        _packageReferences = requiredPackageReferences;
    }
    return self;
}

+ (NSDictionary *)manifestByMergingLayers:(NSArray *)layers {
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (LRManifestLayer *layer in layers) {
        [result setValuesForKeysWithDictionary:layer.manifest];
    }
    return [result copy];
}

+ (NSArray *)packageReferencesWithManifest:(NSDictionary *)manifest {
    LRPackageManager *packageManager = [ActionKitSingleton sharedActionKit].packageManager;
    return [manifest[@"applies_to"] arrayByMappingElementsUsingBlock:^id(NSDictionary *packageInfo) {
        return [packageManager packageReferenceWithDictionary:packageInfo];
    }];
}

@end
