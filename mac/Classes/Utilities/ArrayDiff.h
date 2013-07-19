
#import <Foundation/Foundation.h>

typedef id (^ArrayDiffKeyCallback)(id object);
typedef void (^ArrayDiffAddCallback)(id newObject);
typedef void (^ArrayDiffRemoveCallback)(id oldObject);
typedef void (^ArrayDiffUpdateCallback)(id oldObject, id newObject);

void ArrayDiffWithKeyPath(NSArray *oldObjects, NSArray *newObjects, NSString *identityKeyPath, ArrayDiffAddCallback add, ArrayDiffRemoveCallback remove, ArrayDiffUpdateCallback update);
void ArrayDiffWithKeyCallback(NSArray *oldObjects, NSArray *newObjects, ArrayDiffKeyCallback keyOf, ArrayDiffAddCallback add, ArrayDiffRemoveCallback remove, ArrayDiffUpdateCallback update);
void ArrayDiffWithKeyCallbacks(NSArray *oldObjects, NSArray *newObjects, ArrayDiffKeyCallback keyOfOld, ArrayDiffKeyCallback keyOfNew, ArrayDiffAddCallback add, ArrayDiffRemoveCallback remove, ArrayDiffUpdateCallback update);


@protocol ObjectWithAttributes <NSObject>

- (void)setAttributesDictionary:(NSDictionary *)attributes;

@end

@interface ModelDiffs : NSObject

+ (void)computeDifferenceFromArray:(NSArray *)oldObjects withKeys:(ArrayDiffKeyCallback)keyOfOld toArray:(NSArray *)newObjects withKeys:(ArrayDiffKeyCallback)keyOfNew added:(ArrayDiffAddCallback)added removed:(ArrayDiffRemoveCallback)removed updated:(ArrayDiffUpdateCallback)updated;

+ (void)computeDifferenceFromArray:(NSArray *)oldObjects toArray:(NSArray *)newObjects withKeys:(ArrayDiffKeyCallback)keyBlock added:(ArrayDiffAddCallback)added removed:(ArrayDiffRemoveCallback)removed updated:(ArrayDiffUpdateCallback)updated;

+ (void)computeDifferenceFromArray:(NSArray *)oldObjects toArray:(NSArray *)newObjects withKeyPath:(NSString *)identityKeyPath added:(ArrayDiffAddCallback)added removed:(ArrayDiffRemoveCallback)removed updated:(ArrayDiffUpdateCallback)updated;


+ (void)updateObject:(id)object withAttributeValues:(NSDictionary *)attributeValues;


+ (void)updateMutableObjectsArray:(NSMutableArray *)objects withNewAttributeValueDictionaries:(NSArray *)attributeValueDictionaries identityKeyPath:(NSString *)identityKeyPath identityAttributeKey:(NSString *)identityKey create:(id(^)(NSDictionary *attributes))create update:(void(^)(id object, NSDictionary *attributes))update;

+ (void)updateMutableObjectsArray:(NSMutableArray *)objects withNewAttributeValueDictionaries:(NSArray *)attributeValueDictionaries identityKeyPath:(NSString *)identityKeyPath create:(id(^)(NSDictionary *attributes))create;

+ (void)updateMutableObjectsArray:(NSMutableArray *)objects usingAttributesPropertyWithNewAttributeValueDictionaries:(NSArray *)attributeValueDictionaries identityKeyPath:(NSString *)identityKeyPath identityAttributeKey:(NSString *)identityKey create:(id<ObjectWithAttributes>(^)(NSDictionary *attributes))create;

@end