
#import "LRAssetPackageConfiguration.h"
#import "LRPackageReference.h"
#import "LRPackageManager.h"
#import "AppState.h"


@interface LRAssetPackageConfiguration ()

@end


@implementation LRAssetPackageConfiguration

- (instancetype)initWithManifest:(NSDictionary *)manifest errorSink:(id<LRManifestErrorSink>)errorSink {
    if (self = [super initWithManifest:manifest errorSink:errorSink]) {
        [self load];
    }
    return self;
}

- (void)load {
    _packageReferences = @[];

    LRPackageManager *packageManager = [AppState sharedAppState].packageManager;

    NSArray *packagesData = self.manifest[@"packages"];
    if (![packagesData isKindOfClass:NSArray.class] || packagesData.count == 0) {
        [self addErrorMessage:@"No packages defined in a package configuration"];
        return;
    }

    NSMutableArray *references = [NSMutableArray new];
    for (NSDictionary *packageReferenceData in packagesData) {
        if (![packageReferenceData isKindOfClass:NSDictionary.class]) {
            [self addErrorMessage:@"Packages key of a package configuration must be an array of JSON objects"];
            return;
        }

        LRPackageReference *reference = [packageManager packageReferenceWithDictionary:packageReferenceData];
        if (reference) {
            [references addObject:reference];
        }
    }
    _packageReferences = [references copy];
}

@end
