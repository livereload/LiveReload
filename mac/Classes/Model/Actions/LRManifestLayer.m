
#import "LRManifestLayer.h"
#import "AppState.h"
#import "LRPackageManager.h"

#import "ATFunctionalStyle.h"


@interface LRManifestLayer ()

@end


@implementation LRManifestLayer

- (instancetype)initWithManifest:(NSDictionary *)manifest errorSink:(id<LRManifestErrorSink>)errorSink {
    self = [super initWithManifest:manifest errorSink:errorSink];
    if (self) {
        [self initialize];
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

- (void)initialize {
    LRPackageManager *packageManager = [AppState sharedAppState].packageManager;
    _packageReferences = [self.manifest[@"packages"] arrayByMappingElementsUsingBlock:^id(NSDictionary *packageInfo) {
        return [packageManager packageReferenceWithDictionary:packageInfo];
    }];
}

@end
