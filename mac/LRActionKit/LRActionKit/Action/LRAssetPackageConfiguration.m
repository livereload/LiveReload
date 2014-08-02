@import PackageManagerKit;

#import "LRAssetPackageConfiguration.h"
#import "LRManifestErrorSink.h"
#import "ActionKitSingleton.h"


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

    LRPackageManager *packageManager = [ActionKitSingleton sharedActionKit].packageManager;

    NSArray *packagesData = self.manifest[@"packages"];
    if (![packagesData isKindOfClass:NSArray.class] || packagesData.count == 0) {
        [self addErrorMessage:@"No packages defined in a package configuration"];
        return;
    }

    NSMutableArray *references = [NSMutableArray new];
    for (NSString *packageReferenceData in packagesData) {
        if (![packageReferenceData isKindOfClass:NSString.class]) {
            [self addErrorMessage:@"Packages key of a package configuration must be an array of strings"];
            return;
        }

        LRPackageReference *reference = [packageManager packageReferenceWithString:packageReferenceData];
        if (reference) {
            [references addObject:reference];
        }
    }
    _packageReferences = [references copy];
}

@end
