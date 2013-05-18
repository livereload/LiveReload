
#import "ArrayDiff.h"

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
