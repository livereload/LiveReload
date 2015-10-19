
#import <Foundation/Foundation.h>


@class LRPackageType;
@class LRPackageContainer;
@class LRPackageReference;


NS_ASSUME_NONNULL_BEGIN


@interface LRPackageManager : NSObject

- (void)addPackageType:(LRPackageType *)type;
- (nullable LRPackageType *)packageTypeNamed:(NSString *)name;

@property(nonatomic, readonly) NSArray<LRPackageType *> *packageTypes;

- (void)addPackageContainer:(LRPackageContainer *)container;
- (void)removePackageContainer:(LRPackageContainer *)container;

- (nullable LRPackageReference *)packageReferenceWithDictionary:(NSDictionary *)dictionary;
- (nullable LRPackageReference *)packageReferenceWithString:(NSString *)string;

@end


NS_ASSUME_NONNULL_END
