
#import <Foundation/Foundation.h>


@class LRPackageType;
@class LRPackageReference;
@class LRPackage;
@class RuntimeInstance;


extern NSString *const LRPackageContainerDidChangePackageListNotification;


typedef NS_ENUM(NSInteger, LRPackageContainerType) {
    LRPackageContainerTypeBundled,
    LRPackageContainerTypeRuntimeInstance,
    LRPackageContainerTypeOptionalSet,
    LRPackageContainerTypeProjectLocal
};


@interface LRPackageContainer : NSObject

- (instancetype)initWithPackageType:(LRPackageType *)packageType;

@property(nonatomic, readonly) LRPackageType *packageType;

@property(nonatomic, readonly) NSArray *packages;

@property(nonatomic) LRPackageContainerType containerType;
@property(nonatomic, strong) RuntimeInstance *runtimeInstance;

- (NSArray *)packagesMatchingReference:(LRPackageReference *)reference;
- (LRPackage *)bestPackageMatchingReference:(LRPackageReference *)reference;

- (void)startTrackingPackages;
- (void)endTrackingPackages;

// for subclasses
@property(nonatomic, readonly, getter=isUpdateInProgress) BOOL updateInProgress;
- (void)doUpdate;
- (void)updateSucceededWithPackages:(NSArray *)packages;
- (void)updateFailedWithError:(NSError *)error;

@end
