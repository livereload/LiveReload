
#import <Foundation/Foundation.h>


@class LRPackageReference;
@class LRAssetPackageConfiguration;


// every web site folder might have a different set of local packages, so package resolution depends on the context
@interface LRPackageResolutionContext : NSObject

- (NSArray *)packagesMatchingReference:(LRPackageReference *)reference;

- (NSArray *)packageSetsMatchingConfiguration:(LRAssetPackageConfiguration *)configuration;

@end
