
#import <Foundation/Foundation.h>


@class LRPackage;
@class LRPackageType;
@class LRPackageReference;


// a set of specific package versions (only one version of a package can be included)
@interface LRPackageSet : NSObject

- (instancetype)initWithPackages:(NSArray *)packages;

@property(nonatomic, readonly, copy) NSArray *packages;

@property(nonatomic, readonly) LRPackage *primaryPackage;

- (LRPackage *)packageNamed:(NSString *)name type:(LRPackageType *)type;

- (LRPackage *)packageMatchingReference:(LRPackageReference *)reference;

- (BOOL)matchesAllPackageReferencesInArray:(NSArray *)packageReferences;

@end
