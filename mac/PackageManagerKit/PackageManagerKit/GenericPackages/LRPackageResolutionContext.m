
#import "LRPackageResolutionContext.h"
#import "LRPackageReference.h"
#import "LRPackageType.h"
#import "LRPackageContainer.h"
#import "LRPackageSet.h"


@interface LRPackageResolutionContext ()

@end


@implementation LRPackageResolutionContext

- (NSArray *)packagesMatchingReference:(LRPackageReference *)reference {
    NSMutableArray *result = [NSMutableArray new];
    for (LRPackageContainer *container in reference.type.containers) {
        NSArray *containerPackages = [container packagesMatchingReference:reference];
        [result addObjectsFromArray:containerPackages];
    }
    return [result copy];
}

- (NSArray *)packageSetsMatchingPackageReferences:(NSArray *)packageReferences {
    NSMutableArray *result = [NSMutableArray new];
    NSMutableArray *packages = [NSMutableArray new];
    [self _collectPackageSetsByResolvingRemainingReferences:packageReferences partialResult:packages into:result];
    return [result copy];
}

- (void)_collectPackageSetsByResolvingRemainingReferences:(NSArray *)references partialResult:(NSMutableArray *)packages into:(NSMutableArray *)packageSets {
    if (references.count == 0) {
        [packageSets addObject:[[LRPackageSet alloc] initWithPackages:packages]];
    } else {
        LRPackageReference *reference = [references firstObject];
        NSArray *remainingReferences = [references subarrayWithRange:NSMakeRange(1, references.count - 1)];

        for (LRPackage *candidate in [self packagesMatchingReference:reference]) {
            [packages addObject:candidate];
            [self _collectPackageSetsByResolvingRemainingReferences:remainingReferences partialResult:packages into:packageSets];
            [packages removeLastObject];
        }
    }
}

@end
