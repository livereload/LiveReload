
#import <Foundation/Foundation.h>


@class LRPackageType;
@class LRVersionSet;
@class LRPackage;


@interface LRPackageReference : NSObject

- (instancetype)initWithType:(LRPackageType *)type name:(NSString *)name versionSpec:(LRVersionSet *)versionSet;

@property(nonatomic, readonly) LRPackageType *type;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) LRVersionSet *versionSpec;

- (BOOL)matchesPackage:(LRPackage *)package;

@end
