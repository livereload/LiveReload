// Derived from https://github.com/iMartinKiss/Block-KVO
//
// MIT License
// Copyright (c) 2012—2013 Martin Kiss

#import <Foundation/Foundation.h>


#pragma mark Block Typedefs

typedef void(^MTKBlockGeneric)      (__weak id self,                            id new);
typedef void(^MTKBlockChange)       (__weak id self,                    id old, id new);
typedef void(^MTKBlockChangeMany)   (__weak id self, NSString *keyPath, id old, id new);
typedef void(^MTKBlockInsert)       (__weak id self,                            id new, NSIndexSet *indexes);
typedef void(^MTKBlockRemove)       (__weak id self,                    id old,         NSIndexSet *indexes);
typedef void(^MTKBlockReplace)      (__weak id self,                    id old, id new, NSIndexSet *indexes);

typedef void(^MTKBlockForeignChange)    (__weak id self, __weak id object,                      id old, id new);
typedef void(^MTKBlockForeignChangeMany)(__weak id self, __weak id object, NSString *keyPath,   id old, id new);

typedef void(^MTKBlockNotify)       (__weak id self, NSNotification *notification);

/// Transformation blocks that can be used for map methods.
typedef id(^MTKMappingTransformBlock)(id);
extern MTKMappingTransformBlock const MTKMappingIsNilBlock;         // return @( value == nil );
extern MTKMappingTransformBlock const MTKMappingIsNotNilBlock;      // return @(  value != nil );
extern MTKMappingTransformBlock const MTKMappingInvertBooleanBlock; // return @( ! value.boolValue );
extern MTKMappingTransformBlock const MTKMappingURLFromString;      // return [NSURL URLWithString:value];



@interface NSObject (MTKObserving)

#pragma mark Observe Properties

/**
 Registers observation block for the specified key-path relative to the receiver. **Always call this on `self`.**
 For foreign observations, see methods below.

 Observation block is executed immediately and at least once for every change of value in the property.
 The block receives old and new value of the property. First call to this block will have `nil` as `old` and current value as `new`.

 Internal check prevents calling the block when the value actualy did not changed, so old and new should never be equal.
 Assignment that do not really change the value (e.g. self.title = self.title) is ignored. Checking is done using `==` and `-isEqual:`.

 This block has also reference to the receiver (which should always be the caller). This internal `self` makes it easier
 to avoid retain cycles. It overrides local variable `self` (method argument) and declares it as weak. **Use of this weak
 `self` inside the block does not create retain cycle.** To make sure “outside” and “inside” `self` variables contains the same
 object, caller should always be the receiver.

 If you call this method multiple times on the same key-path it is guaranteed they will be executed in the same order.

 For cleanup, call `-removeAllObservations` in dealloc.

 @param keyPath
 The key-path, relative to the receiver, of the property to observe. This value must not be `nil`.

 @param observationBlock
 Block to be executed when the value on specified key-path changes. This value must not be `nil`.
 */
- (void)observeProperty:(NSString *)keyPath withBlock:(MTKBlockChange)observationBlock;

/// Calls `-observeProperty:withBlock:` for each key-path.
- (void)observeProperties:(NSArray *)keyPaths withBlock:(MTKBlockChangeMany)observationBlock;

/// Calls `-observeProperty:withBlock:` with block that performs given selector. Allowed formats: `-didChangeProperty`, `-didChangePropertyTo:`, `-didChangePropertyFrom:to:`
- (void)observeProperty:(NSString *)keyPath withSelector:(SEL)observationSelector;

/// Calls `-observeProperty:withSelector:` for each key-path.
- (void)observeProperties:(NSArray *)keyPaths withSelector:(SEL)observationSelector;


#pragma mark Observe Foreign Property

/**
 Registers observation block for the specified key-path relative to the object. **You should call this method on `self`,
 since you are the owner of the observation.**
 Owner of the block itself is observed object, but you can use it in block since it comes as an argument (use __weak).

 Observation block is executed immediately and at least once for every change of value in the property.
 The block receives old and new value of the property. First call to this block will have `nil` as `old` and current value as `new`.

 Internal check prevents calling the block when the value actualy did not changed, so old and new should never be equal.
 Assignment that do not really change the value (e.g. self.title = self.title) is ignored. Checking is done using `==` and `-isEqual:`.

 This block has also reference to the receiver (which should always be the caller).
 This prevents potential retain cycles, but is not so important as in `-observeProperty:withBlock:`

 If you call this method multiple times on the same key-path it is guaranteed they will be executed in the same order.

 For cleanup, call `-removeAllObservationsOfObject:` once you do not need that object.

 @param keyPath
 The key-path, relative to the receiver, of the property to observe. This value must not be `nil`.

 @param object
 Observed object.

 @param observationBlock
 Block to be executed when the value on specified key-path changes. This value must not be `nil`.
 */
- (void)observeObject:(id)object property:(NSString *)keyPath withBlock:(MTKBlockForeignChange)block;

/// Calls `-observeObject:property:withBlock:` for each property.
- (void)observeObject:(id)object properties:(NSArray *)keyPaths withBlock:(MTKBlockForeignChangeMany)block;

/// Calls `-observeObject:property:withBlock:` with block that invokes selector. Allowed selectors of format: `-objectDidChangeTitle:`, `-object:didChangeTitle:`, `-object:didChangeTitleFrom:to:`.
- (void)observeObject:(id)object property:(NSString *)keyPath withSelector:(SEL)selector;

/// Calls `-observeObject:property:withSelector:` for each property.
- (void)observeObject:(id)object properties:(NSArray *)keyPaths withSelector:(SEL)selector;


#pragma mark Observe Relationships

/**
 Observe relationship. See KVC documentation for full explanation how relationships work. Basically there are two options:

 1. You implement KVC methods for relationship yourself.

 2. Use Core Data relationships.

 Relationship is a collection object (NSArray, NSSet, NSOrderedSet, maybe some other...) with accessor methods.
 This collection should be modified only through these accessor for changes to be observable.
 There are 3 way how the collection may be modified:

 1. Insert one or more objects.

 2. Remove one or more objects.

 3. Replace one or more objects with the same number of other objects.

 In addition there is fourth case of modification - you assign completely new collection object to the property (in case it has setter).
 This method allows you to observe all 4 modifications to the relationship with one call using blocks.

 Blocks that receive old and new values have declared arguments type as `id`. They are always of the same class as observed collection.
 Some of the blocks have argument `indexes`. In case of non-indexed collection it contains `nil`.
 This behavior is consistent with standard KVO observation method.

 For cleanup, call `-removeAllObservations` in dealloc.

 @param changeBlock Called when the collection is completely replaced by new collection. Called also for any other modification type where you do not specify any block.
 @param insertionBlock Called when some objects are inserted into relationship. You receive those objects (in the same collection class) and their indexes (if the colelction is indexed). You may pass nil value and `changeBlock` will be invoked instead.
 @param removalBlock Called when some objects are removed from relationship. You receive those objects (in the same collection class) and their past indexes (if the colelction is indexed). You may pass nil value and `changeBlock` will be invoked instead.
 @param replacementBlock Called when some objects are replacedby other objects. You receive old and new objects (in the same collection class) and indexes (if the colelction is indexed). You may pass nil value and `changeBlock` will be invoked instead.

 */
- (void)observeRelationship:(NSString *)keyPath
                changeBlock:(MTKBlockChange)changeBlock
             insertionBlock:(MTKBlockInsert)insertionBlock
               removalBlock:(MTKBlockRemove)removalBlock
           replacementBlock:(MTKBlockReplace)replacementBlock;

/// Calls `-observeRelationship:changeBlock:insertionBlock:removalBlock:replacementBlock:` with only change block.
- (void)observeRelationship:(NSString *)keyPath changeBlock:(MTKBlockGeneric)changeBlock;


// No foreign relationships yet, but do you really need this kind of stuff?


#pragma mark Map Properties

/**
 Creates one directional binding from source to destination key-paths. This method calls `-observeProperty:withBlock:`,
 so the same rules apply.

 This method begins observing the source key-path and everytime time value changes, executes transformatinon block, if
 any. Then it sets this value to destination key-path.

 Method is recursion-safe, so you can create bi-directional bindings.

 For cleanup, call `-removeAllObservations` in dealloc.

 @param sourceKeyPath
 Key-path relative to the receiver that will be observed. This value must not be `nil`.

 @param destinationKeyPath
 Key-path relative to the receiver whose value will be set everytime the source chanegs. This value must not be `nil`.

 @param transformationBlock
 Optional block that takes the value from source as argument and its returned value will be set to destination. Here you
 are supposed to make any transformations needed. There is no internal check for returned value.
 */
- (void)map:(NSString *)sourceKeyPath to:(NSString *)destinationKeyPath transform:(id (^)(id value))transformationBlock;

/// Calls `-map:to:transform:` with transformation block that replaces `nil` value by given object.
- (void)map:(NSString *)sourceKeyPath to:(NSString *)destinationKeyPath null:(id)nullReplacement;


// No foreign mapping yet, but do you really need this kind of stuff?


#pragma mark Notifications

/**
 Registers block observer using NSNotificationCenter and current operation queue.
 See `-[NSNotificationCenter addObserverForName:object:queue:usingBlock:]` for more info.

 For cleanup, call `-removeAllObservations` in dealloc.
 */
- (void)observeNotification:(NSString *)name fromObject:(id)object withBlock:(MTKBlockNotify)block;

/// Calls `-observeNotification:fromObject:withBlock:` with nil object.
- (void)observeNotification:(NSString *)name withBlock:(MTKBlockNotify)block;

/// Calls `-observeNotification:fromObject:withBlock:` for each combination of name and object. `objects` may be nil, but can not be an empty array, because nothing will be registered.
- (void)observeNotifications:(NSArray *)names fromObjects:(NSArray *)objects withBlock:(MTKBlockNotify)block;


#pragma mark Removing

/**
 Removes all observations registered with the receiver. Should be always called on `self`.
 */
- (void)removeAllObservations;

/**
 Removes all observations registered on given object. Should be always called on `self`.
 */
- (void)removeAllObservationsOfObject:(id)object;


@end



#pragma mark -

/**
 This is private class. This is the object that holds observation blocks and observes given property using standatd KVO.
 For multiple observations of the same key-path (and object) only one observer is used.
 */
@interface MTKObserver : NSObject


#pragma mark Initialization
/// Do not use. Observation target will be nil, so any calls to it will have no effect.
- (id)init;
/// Designated initializer.
- (id)initWithTarget:(NSObject *)target keyPath:(NSString *)keyPath owner:(id)owner;


#pragma mark Ownership
/// Object that 'owns' all blocks in this observer. This object was the caller of observation method.
@property (nonatomic, readonly, assign) id owner;


#pragma mark Attaching
/// Attached means, that this object really observes the key-path it was initialized with. Set it to add/remove this observer.
@property (nonatomic, readwrite, assign) BOOL attached;
/// Convenience method to set `attached` to YES.
- (void)attach;
/// Convenience method to set `attached` to NO.
- (void)detach;


#pragma mark Blocks
/// Add block to be executed on key-path setting of simple property or relationship.
- (void)addSettingObservationBlock:(MTKBlockChange)block;
/// Add block to be executed on key-path relationship insertion.
- (void)addInsertionObservationBlock:(MTKBlockInsert)block;
/// Append block to be executed on key-path relationship removal.
- (void)addRemovalObservationBlock:(MTKBlockRemove)block;
/// Add block to be executed on key-path relationship replacement.
- (void)addReplacementObservationBlock:(MTKBlockReplace)block;


@end
