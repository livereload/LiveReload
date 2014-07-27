
#import <Foundation/Foundation.h>


@class LRPackageReference;


// every web site folder might have a different set of local packages, so package resolution depends on the context
@interface LRPackageResolutionContext : NSObject

- (NSArray *)packagesMatchingReference:(LRPackageReference *)reference;

// rename from packageSetsMatchingConfiguration
- (NSArray *)packageSetsMatchingPackageReferences:(NSArray *)packageReferences;

@end
