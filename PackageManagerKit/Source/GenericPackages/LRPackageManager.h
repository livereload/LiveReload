
#import <Foundation/Foundation.h>


@class LRPackageType;
@class LRPackageContainer;
@class LRPackageReference;


@interface LRPackageManager : NSObject

- (void)addPackageType:(LRPackageType *)type;
- (LRPackageType *)packageTypeNamed:(NSString *)name;

@property(nonatomic, readonly) NSArray *packageTypes;

- (void)addPackageContainer:(LRPackageContainer *)container;
- (void)removePackageContainer:(LRPackageContainer *)container;

- (LRPackageReference *)packageReferenceWithDictionary:(NSDictionary *)dictionary;
- (LRPackageReference *)packageReferenceWithString:(NSString *)string;

@end
