
#import <Foundation/Foundation.h>

typedef id (^ArrayDiffKeyCallback)(id object);
typedef void (^ArrayDiffAddCallback)(id newObject);
typedef void (^ArrayDiffRemoveCallback)(id oldObject);
typedef void (^ArrayDiffUpdateCallback)(id oldObject, id newObject);

void ArrayDiffWithKeyPath(NSArray *oldObjects, NSArray *newObjects, NSString *identityKeyPath, ArrayDiffAddCallback add, ArrayDiffRemoveCallback remove, ArrayDiffUpdateCallback update);
void ArrayDiffWithKeyCallback(NSArray *oldObjects, NSArray *newObjects, ArrayDiffKeyCallback keyOf, ArrayDiffAddCallback add, ArrayDiffRemoveCallback remove, ArrayDiffUpdateCallback update);
void ArrayDiffWithKeyCallbacks(NSArray *oldObjects, NSArray *newObjects, ArrayDiffKeyCallback keyOfOld, ArrayDiffKeyCallback keyOfNew, ArrayDiffAddCallback add, ArrayDiffRemoveCallback remove, ArrayDiffUpdateCallback update);
