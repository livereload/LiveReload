
#import "ATObservation.h"
#import <objc/runtime.h>
#import <objc/message.h>



#pragma mark Private Interface

@interface MTKObserver ()

@property (nonatomic, readwrite, assign) id target;
@property (nonatomic, readwrite, copy) NSString *keyPath;
@property (nonatomic, readwrite, assign) id owner;


@property (nonatomic, readwrite, strong) NSMutableArray *afterSettingBlocks;
@property (nonatomic, readwrite, strong) NSMutableArray *afterInsertionBlocks;
@property (nonatomic, readwrite, strong) NSMutableArray *afterRemovalBlocks;
@property (nonatomic, readwrite, strong) NSMutableArray *afterReplacementBlocks;

@end



@implementation MTKObserver


#pragma mark Initialization

- (id)init {
    return [self initWithTarget:nil keyPath:nil owner:nil];
}

- (id)initWithTarget:(NSObject *)target keyPath:(NSString *)keyPath owner:(id)owner {
    self = [super init];
    if (self) {
        self.target = target;
        self.keyPath = keyPath;
		self.owner = owner;

        self.afterSettingBlocks = [[NSMutableArray alloc] init];
        self.afterInsertionBlocks = [[NSMutableArray alloc] init];
        self.afterRemovalBlocks = [[NSMutableArray alloc] init];
        self.afterReplacementBlocks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
	//NSLog(@"Observer dealloc %@ %@", self.target, self.keyPath);
}



#pragma mark Adding Blocks

- (void)addSettingObservationBlock:(MTKBlockChange)block {
    [self.afterSettingBlocks addObject:block];

    // Since we supress equal values in observation, to we must manually ensure the block is invoked.
    // In this only case the old and new values are equal (if the initial value is `nil`).
    id initialValue = [self.target valueForKeyPath:self.keyPath];
    block(self.target, nil, initialValue);
}

- (void)addInsertionObservationBlock:(MTKBlockInsert)block {
    [self.afterInsertionBlocks addObject:block];
}

- (void)addRemovalObservationBlock:(MTKBlockRemove)block {
    [self.afterRemovalBlocks addObject:block];
}

- (void)addReplacementObservationBlock:(MTKBlockReplace)block {
    [self.afterReplacementBlocks addObject:block];
}



#pragma mark Attaching

- (void)setAttached:(BOOL)attached {
    // In case there is some other value than YES or NO.
    if (attached != NO) {
        attached = YES;
    }
    // Do not catch exceptions, observing invalid key-path is considered programmer error.
    if (self->_attached != attached) {
        self->_attached = attached;
        if (attached) {
            [self.target addObserver:self
                          forKeyPath:self.keyPath
                             options:
             NSKeyValueObservingOptionInitial |
             NSKeyValueObservingOptionOld |
             NSKeyValueObservingOptionNew
                             context:nil];
        }
        else {
            [self.target removeObserver:self forKeyPath:self.keyPath];
        }
    }
}

- (void)attach {
    self.attached = YES;
}

- (void)detach {
    self.attached = NO;
}



#pragma mark Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (self.target == object && [self.keyPath isEqualToString:keyPath]) {

		BOOL isPrior = [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
        NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];

        id old = [change objectForKey:NSKeyValueChangeOldKey];
        if (old == [NSNull null]) old = nil;

		id new = [change objectForKey:NSKeyValueChangeNewKey];
        if (new == [NSNull null]) new = nil;

		NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];

		if (isPrior) {
            // May be added in future.
        }
        else {
            switch (changeKind) {
                case NSKeyValueChangeSetting: [self executeAfterSettingBlocksOld:old new:new]; break;
                case NSKeyValueChangeInsertion: [self executeAfterInsertionBlocksNew:new indexes:indexes]; break;
                case NSKeyValueChangeRemoval: [self executeAfterRemovalBlocksOld:old indexes:indexes]; break;
                case NSKeyValueChangeReplacement: [self executeAfterReplacementBlocksOld:old new:new indexes:indexes]; break;
            }
        }
    }
}



#pragma mark Execute Blocks

- (void)executeAfterSettingBlocksOld:(id)old new:(id)new {
	// Here we check for equality. Two values are equal when they have equal pointers (e.g. nils) or they respond to -isEqual: with YES.
    if (old == new || (old && [new isEqual:old])) return;

    for (MTKBlockChange block in [self.afterSettingBlocks copy]) {
        block(self.target, old, new);
    }
}

- (void)executeAfterInsertionBlocksNew:(id)new indexes:(NSIndexSet *)indexes {
	// Prevent calling blocks when really nothing was inserted.
    if ([new respondsToSelector:@selector(count)] && [new count] == 0) return;

    for (MTKBlockInsert block in [self.afterInsertionBlocks copy]) {
        block(self.target, new, indexes);
    }
}

- (void)executeAfterRemovalBlocksOld:(id)old indexes:(NSIndexSet *)indexes {
	// Prevent calling blocks when really nothing was removed.
    if ([old respondsToSelector:@selector(count)] && [old count] == 0) return;

    for (MTKBlockRemove block in [self.afterRemovalBlocks copy]) {
        block(self.target, old, indexes);
    }
}

- (void)executeAfterReplacementBlocksOld:(id)old new:(id)new indexes:(NSIndexSet *)indexes {
	// Prevent calling blocks when really nothing was replaced.
    if ([old respondsToSelector:@selector(count)] && [old count] == 0) return;
    if ([new respondsToSelector:@selector(count)] && [new count] == 0) return;

    for (MTKBlockReplace block in [self.afterReplacementBlocks copy]) {
        block(self.target, old, new, indexes);
    }
}



@end


#pragma mark -

@implementation NSObject (MTKObserving)


#pragma mark Internal

/// Getter for dictionary containing all registered observers for this object. Keys are observed key-paths.
- (NSMutableDictionary *)mtk_keyPathBlockObservers {
    // Observer is hidden object that has target (this object), key path and owner.
    // There should never exist two or more observers with the same target, key path and owner.
    // Observer has multiple observation block which are executed in order they were added.
    static char associationKey;
    NSMutableDictionary *keyPathObservers = objc_getAssociatedObject(self, &associationKey);
    if ( ! keyPathObservers) {
        keyPathObservers = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self,
                                 &associationKey,
                                 keyPathObservers,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return keyPathObservers;
}

/// Find existing observer or create new for this key-path and owner. Multiple uses of one key-path per owner return the same observer.
- (MTKObserver *)mtk_observerForKeyPath:(NSString *)keyPath owner:(id)owner {
	MTKObserver *observer = nil;
    // Key path is used as key to retrieve observer.
	// For one key-path may be more observers with different owners.

    // Obtain the set
    NSMutableSet *observersForKeyPath = [[self mtk_keyPathBlockObservers] objectForKey:keyPath];
	if ( ! observersForKeyPath) {
        // Nothing found for this key-path
		observersForKeyPath = [[NSMutableSet alloc] init];
		[[self mtk_keyPathBlockObservers] setObject:observersForKeyPath forKey:keyPath];
	}
	else {
        // Find the one with this owner
		for (MTKObserver *existingObserver in observersForKeyPath) {
			if (existingObserver.owner == owner) {
				observer = existingObserver;
				break;
			}
		}
	}
    // Now the observer itself
	if ( ! observer) {
		observer = [[MTKObserver alloc] initWithTarget:self keyPath:keyPath owner:owner];
        [observersForKeyPath addObject:observer];
        [observer attach];
    }
    return observer;
}

/// Getter for set containing all registered notification observers for this object. See `NSNotificationCenter`.
- (NSMutableSet *)mtk_notificationBlockObservers {
    static char associationKey;
    NSMutableSet *notificationObservers = objc_getAssociatedObject(self, &associationKey);
    if ( ! notificationObservers) {
        notificationObservers = [[NSMutableSet alloc] init];
        objc_setAssociatedObject(self,
                                 &associationKey,
                                 notificationObservers,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return notificationObservers;
}

/// Called internally by the owner.
- (void)mtk_removeAllObservationsForOwner:(id)owner {
	for (NSMutableSet *observersForKeyPath in [[self mtk_keyPathBlockObservers] allValues]) {
		for (MTKObserver *observer in [observersForKeyPath copy]) {
			if (observer.owner == owner) {
				[observer detach];
				[observersForKeyPath removeObject:observer];
			}
		}
	}
}





#pragma mark Observe Properties

- (void)observeProperty:(NSString *)keyPath withBlock:(MTKBlockChange)observationBlock {
    [self observeObject:self property:keyPath withBlock:^(__weak id weakSelf, __weak id weakObject, id old, id new) {
        // weakSelf and weakObject are the same
        observationBlock(weakSelf, old, new);
    }];
}

- (void)observeProperties:(NSArray *)keyPaths withBlock:(MTKBlockChangeMany)observationBlock {
    [self observeObject:self properties:keyPaths withBlock:^(__weak id weakSelf, __weak id weakObject, NSString *keyPath, id old, id new) {
        // weakSelf and weakObject are the same
        observationBlock(weakSelf, keyPath, old, new);
    }];
}

- (void)observeProperty:(NSString *)keyPath withSelector:(SEL)observationSelector {
	[self observeObject:self property:keyPath withSelector:observationSelector];
}

- (void)observeProperties:(NSArray *)keyPaths withSelector:(SEL)observationSelector {
    [self observeObject:self properties:keyPaths withSelector:observationSelector];
}





#pragma mark Foreign Property

/// Add observation block to appropriate observer.
- (void)observeObject:(id)object property:(NSString *)keyPath withBlock:(MTKBlockForeignChange)observationBlock {
    __weak typeof(self) weakSelf = self;
	MTKObserver *observer = [object mtk_observerForKeyPath:keyPath owner:self];
	[observer addSettingObservationBlock:^(__weak id weakObject, id old, id new) {
        observationBlock(weakSelf, weakObject, old, new);
    }];
}

/// Register the block for all given key-paths.
- (void)observeObject:(id)object properties:(NSArray *)keyPaths withBlock:(MTKBlockForeignChangeMany)observationBlock {
	for (NSString *keyPath in keyPaths) {
        NSString *keyPathCopy = [keyPath copy]; // If some fool uses mutable key-paths
        [self observeObject:object property:keyPath withBlock:^(__weak id weakSelf, __weak id weakObject, id old , id new){
            observationBlock(weakSelf, weakObject, keyPathCopy, old, new);
        }];
    }
}

/// Register block invoking given selector. Smart detecting of number of arguments.
- (void)observeObject:(id)object property:(NSString *)keyPath withSelector:(SEL)observationSelector {
	NSMethodSignature *signature = [self methodSignatureForSelector:observationSelector];
    NSInteger numberOfArguments = [signature numberOfArguments];
	[self observeObject:object property:keyPath withBlock:^(__weak id weakSelf, __weak id weakObject, id old, id new) {
		switch (numberOfArguments) {
            case 0:
            case 1:
                [NSException raise:NSInternalInconsistencyException format:@"WTF?! Method should have at least two arguments: self and _cmd!"];
                break;

            case 2: // +0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                // -someObjectDidChangeSomething
                [weakSelf performSelector:observationSelector];
                break;

            case 3: // +1
                if (weakSelf == weakObject) {
                    // -didChangeSomethingTo:
                    [weakSelf performSelector:observationSelector withObject:new]; // Observing self, we dont need self
                }
                else {
                    // -someObjectDidChangeSomething:
                    [weakSelf performSelector:observationSelector withObject:weakObject]; // Observing another object
                }
                break;

			case 4: // +2
                if (weakSelf == weakObject) {
                    // -didChangeSomethingFrom:to:
                    [weakSelf performSelector:observationSelector withObject:old withObject:new];
                }
				else {
                    // -someObject: didChangeSomethingTo:
                    [weakSelf performSelector:observationSelector withObject:weakObject withObject:new];
                }
                break;
#pragma clang diagnostic pop

            default:// +3
                // -someObject:didChangeSomethingFrom:to:
                objc_msgSend(weakSelf, observationSelector, weakObject, old, new); // Fuck off NSInvocation!
                break;
        }
	}];
}

/// Register the selector for each key-path.
- (void)observeObject:(id)object properties:(NSArray *)keyPaths withSelector:(SEL)observationSelector {
	for (NSString *keyPath in keyPaths) {
        [self observeObject:object property:keyPath withSelector:observationSelector];
    }
}





#pragma mark Observe Relationships

/// Add observation blocks to appropriate observer. If some block was not specified, use the `changeBlock`.
- (void)observeRelationship:(NSString *)keyPath
                changeBlock:(MTKBlockChange)changeBlock
             insertionBlock:(MTKBlockInsert)insertionBlock
               removalBlock:(MTKBlockRemove)removalBlock
           replacementBlock:(MTKBlockReplace)replacementBlock
{
    MTKObserver *observer = [self mtk_observerForKeyPath:keyPath owner:self];
    [observer addSettingObservationBlock:changeBlock];
    [observer addInsertionObservationBlock: insertionBlock ?: ^(__weak id weakSelf, id new, NSIndexSet *indexes) {
        // If no insertion block was specified, call general change block.
        changeBlock(weakSelf, nil, [weakSelf valueForKeyPath:keyPath]);
    }];
    [observer addRemovalObservationBlock: removalBlock ?: ^(__weak id weakSelf, id old, NSIndexSet *indexes) {
        // If no removal block was specified, call general change block.
        changeBlock(weakSelf, nil, [weakSelf valueForKeyPath:keyPath]);
    }];
    [observer addReplacementObservationBlock: replacementBlock ?: ^(__weak id weakSelf, id old, id new, NSIndexSet *indexes) {
        // If no removal block was specified, call general change block.
        changeBlock(weakSelf, nil, [weakSelf valueForKeyPath:keyPath]);
    }];
}

/// Call main `-observeRelationship:...` method with only first argument.
- (void)observeRelationship:(NSString *)keyPath changeBlock:(MTKBlockGeneric)changeBlock {
    [self observeRelationship:keyPath
                  changeBlock:^(__weak id weakSelf, id old, id new) {
                      changeBlock(weakSelf, new);
                  }
               insertionBlock:nil
                 removalBlock:nil
             replacementBlock:nil];
}





#pragma mark Map Properties

/// Call `-map:to:transform:` with transform block that uses returns the same value, or null replacement.
- (void)map:(NSString *)sourceKeyPath to:(NSString *)destinationKeyPath null:(id)nullReplacement {
    [self map:sourceKeyPath to:destinationKeyPath transform:^id(id value) {
        return value ?: nullReplacement;
    }];
}

/// Observe source key-path and set its new value to destination every time it changes. Use transformation block, if specified.
- (void)map:(NSString *)sourceKeyPath to:(NSString *)destinationKeyPath transform:(id (^)(id))transformationBlock {
    [self observeProperty:sourceKeyPath withBlock:^(__weak id weakSelf, id old, id new) {
        id transformedValue = (transformationBlock? transformationBlock(new) : new);
        [weakSelf setValue:transformedValue forKeyPath:destinationKeyPath];
    }];
}





#pragma mark Notifications

/// Call another one.
- (void)observeNotification:(NSString *)name withBlock:(MTKBlockNotify)block {
	[self observeNotification:name fromObject:nil withBlock:block];
}

/// Add block observer on current operation queue and the resulting internal opaque observe is stored in associated mutable set.
- (void)observeNotification:(NSString *)name fromObject:(id)object withBlock:(MTKBlockNotify)block {
	__weak typeof(self) weakSelf = self;
    // Invoke manually for the first time.
    block(weakSelf, nil);
	id internalObserver = [[NSNotificationCenter defaultCenter] addObserverForName:name
																			object:object
																			 queue:[NSOperationQueue currentQueue]
																		usingBlock:^(NSNotification *notification) {
																			block(weakSelf, notification);
																		}];
	[[self mtk_notificationBlockObservers] addObject:internalObserver];
}

/// Make all combination of name and object (if any are given) and call main notification observing method.
- (void)observeNotifications:(NSArray *)names fromObjects:(NSArray *)objects withBlock:(MTKBlockNotify)block {
	for (NSString *name in names) {
		if (objects) {
			for (id object in objects) {
				[self observeNotification:name fromObject:object withBlock:block];
			}
		}
		else {
			[self observeNotification:name fromObject:nil withBlock:block];
		}
	}
}





#pragma mark Removing

/// Called usually from dealloc (may be called at any time). Detach all observers. The associated objects are released once the deallocation process finishes.
- (void)removeAllObservations {
	// Key-Path Observers
    NSMutableDictionary *keyPathBlockObservers = [self mtk_keyPathBlockObservers];
	for (NSMutableSet *observersForKeyPath in [[self mtk_keyPathBlockObservers] allValues]) {
        [observersForKeyPath makeObjectsPerformSelector:@selector(detach)];
        [observersForKeyPath removeAllObjects];
	}
    [keyPathBlockObservers removeAllObjects];

    // NSNotification Observers
	NSMutableSet *notificationObservers = [self mtk_notificationBlockObservers];
	for (id internalObserver in notificationObservers) {
		[[NSNotificationCenter defaultCenter] removeObserver:internalObserver];
	}
	[notificationObservers removeAllObjects];
}

/// Called at any time, tell the observed object to remove our observation blocks.
- (void)removeAllObservationsOfObject:(id)object {
	[object mtk_removeAllObservationsForOwner:self];
}





@end






MTKMappingTransformBlock const MTKMappingIsNilBlock = ^NSNumber *(id value){
    return @( value == nil );
};

MTKMappingTransformBlock const MTKMappingIsNotNilBlock = ^NSNumber *(id value){
    return @( value != nil );
};

MTKMappingTransformBlock const MTKMappingInvertBooleanBlock = ^NSNumber *(NSNumber *value){
    return @( ! value.boolValue );
};

MTKMappingTransformBlock const MTKMappingURLFromStringBlock = ^NSURL *(NSString *value){
    return [NSURL URLWithString:value];
};


