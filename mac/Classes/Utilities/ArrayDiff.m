
#import "ArrayDiff.h"
#import <objc/runtime.h>

void ArrayDiffWithKeyPath(NSArray *oldObjects, NSArray *newObjects, NSString *identityKeyPath, ArrayDiffAddCallback add, ArrayDiffRemoveCallback remove, ArrayDiffUpdateCallback update) {
    ArrayDiffWithKeyCallback(oldObjects, newObjects, ^(id obj) {
        return [obj valueForKeyPath:identityKeyPath];
    }, add, remove, update);
}

void ArrayDiffWithKeyCallback(NSArray *oldObjects, NSArray *newObjects, ArrayDiffKeyCallback keyOf, ArrayDiffAddCallback add, ArrayDiffRemoveCallback remove, ArrayDiffUpdateCallback update) {
    ArrayDiffWithKeyCallbacks(oldObjects, newObjects, keyOf, keyOf, add, remove, update);
}

void ArrayDiffWithKeyCallbacks(NSArray *oldObjects, NSArray *newObjects, ArrayDiffKeyCallback keyOfOld, ArrayDiffKeyCallback keyOfNew, ArrayDiffAddCallback add, ArrayDiffRemoveCallback remove, ArrayDiffUpdateCallback update) {
    NSMutableDictionary *keysToOldObjects = [NSMutableDictionary dictionary];
    for (id oldObject in oldObjects) {
        id key = keyOfOld(oldObject);
        [keysToOldObjects setObject:oldObject forKey:key];
    }

    for (id newObject in newObjects) {
        id key = keyOfNew(newObject);
        id oldObject = [keysToOldObjects objectForKey:key];
        if (oldObject) {
            update(oldObject, newObject);
            [keysToOldObjects removeObjectForKey:key];
        } else {
            add(newObject);
        }
    }

    for (id removedObject in [keysToOldObjects allValues]) {
        remove(removedObject);
    }
}


@implementation ModelDiffs

+ (void)computeDifferenceFromArray:(NSArray *)oldObjects withKeys:(ArrayDiffKeyCallback)keyOfOld toArray:(NSArray *)newObjects withKeys:(ArrayDiffKeyCallback)keyOfNew added:(ArrayDiffAddCallback)added removed:(ArrayDiffRemoveCallback)removed updated:(ArrayDiffUpdateCallback)updated {
    ArrayDiffWithKeyCallbacks(oldObjects, newObjects, keyOfOld, keyOfNew, added, removed, updated);
}

+ (void)computeDifferenceFromArray:(NSArray *)oldObjects toArray:(NSArray *)newObjects withKeys:(ArrayDiffKeyCallback)keyBlock added:(ArrayDiffAddCallback)added removed:(ArrayDiffRemoveCallback)removed updated:(ArrayDiffUpdateCallback)updated {
    return [self computeDifferenceFromArray:oldObjects withKeys:keyBlock toArray:newObjects withKeys:keyBlock added:added removed:removed updated:updated];
}

+ (void)computeDifferenceFromArray:(NSArray *)oldObjects toArray:(NSArray *)newObjects withKeyPath:(NSString *)identityKeyPath added:(ArrayDiffAddCallback)added removed:(ArrayDiffRemoveCallback)removed updated:(ArrayDiffUpdateCallback)updated {
    return [self computeDifferenceFromArray:oldObjects toArray:newObjects withKeys:^(id obj) {
        return [obj valueForKeyPath:identityKeyPath];
    } added:added removed:removed updated:updated];
}

static const char *UpdateObjectPreviousKeysAttachment = "UpdateObjectPreviousKeysAttachment";

+ (void)updateObject:(id)object withAttributeValues:(NSDictionary *)attributeValues {
    [object setValuesForKeysWithDictionary:attributeValues];

    // the set of keys that has been set previously is stored as an associated object
    NSSet *newKeys = [NSSet setWithArray:[attributeValues allKeys]];
    NSMutableSet *removedKeys = [objc_getAssociatedObject(object, UpdateObjectPreviousKeysAttachment) mutableCopy];
    [removedKeys minusSet:newKeys];
    objc_setAssociatedObject(object, UpdateObjectPreviousKeysAttachment, newKeys, OBJC_ASSOCIATION_RETAIN);

    // nillify any previously set keys that are no longer provided
    for (NSString *key in removedKeys) {
        [object setValue:nil forKey:key];
    }
}

+ (void)updateMutableObjectsArray:(NSMutableArray *)objects withNewAttributeValueDictionaries:(NSArray *)attributeValueDictionaries identityKeyPath:(NSString *)identityKeyPath identityAttributeKey:(NSString *)identityKey create:(id(^)(NSDictionary *attributes))create update:(void(^)(id object, NSDictionary *attributes))update delete:(void(^)(id))delete {
    [self computeDifferenceFromArray:objects withKeys:^id(id object) {
        return [object valueForKeyPath:identityKeyPath];
    } toArray:attributeValueDictionaries withKeys:^id(NSDictionary *attributes) {
        return attributes[identityKey];
    } added:^(NSDictionary *newAttributes) {
        id object = create(newAttributes);
        update(object, newAttributes);
        [objects addObject:object];
    } removed:^(id oldObject) {
        delete(oldObject);
        [objects removeObject:oldObject];
    } updated:update];
}

+ (void)updateMutableObjectsArray:(NSMutableArray *)objects withNewAttributeValueDictionaries:(NSArray *)attributeValueDictionaries identityKeyPath:(NSString *)identityKeyPath create:(id(^)(NSDictionary *attributes))create delete:(void(^)(id))delete {
    return [self updateMutableObjectsArray:objects withNewAttributeValueDictionaries:attributeValueDictionaries identityKeyPath:identityKeyPath identityAttributeKey:identityKeyPath create:create update:^(id object, NSDictionary *attributes) {
        [self updateObject:object withAttributeValues:attributes];
    } delete:delete];
}

+ (void)updateMutableObjectsArray:(NSMutableArray *)objects usingAttributesPropertyWithNewAttributeValueDictionaries:(NSArray *)attributeValueDictionaries identityKeyPath:(NSString *)identityKeyPath identityAttributeKey:(NSString *)identityKey create:(id<ObjectWithAttributes>(^)(NSDictionary *attributes))create delete:(void(^)(id))delete {
    return [self updateMutableObjectsArray:objects withNewAttributeValueDictionaries:attributeValueDictionaries identityKeyPath:identityKeyPath identityAttributeKey:identityKey create:create update:^(id<ObjectWithAttributes> object, NSDictionary *attributes) {
        [object setAttributesDictionary:attributes];
    } delete:delete];
}

@end
