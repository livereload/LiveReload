
#import "Bag.h"


@implementation Bag

@synthesize dictionary=_dictionary;

- (id)init {
    self = [super init];
    if (self) {
        _dictionary = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)dealloc {
    [_dictionary release], _dictionary = nil;
    [super dealloc];
}


#pragma mark -

- (void)multipleValuesChanged {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
}

- (void)valueDidChangeForKey:(NSString *)key {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
}


#pragma mark -

- (NSUInteger)count {
    return [_dictionary count];
}

- (id)objectForKey:(id)aKey {
    return [_dictionary objectForKey:aKey];
}


#pragma mark -

- (id)valueForKey:(NSString *)key {
    return [_dictionary objectForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)aKey {
    [_dictionary setObject:value forKey:aKey];
    [self valueDidChangeForKey:aKey];
}



#pragma mark -

- (void)removeObjectForKey:(id)aKey {
    [_dictionary removeObjectForKey:aKey];
    [self valueDidChangeForKey:aKey];
}

- (void)setObject:(id)anObject forKey:(id)aKey {
    [_dictionary setObject:anObject forKey:aKey];
    [self valueDidChangeForKey:aKey];
}


#pragma mark -

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
    [_dictionary addEntriesFromDictionary:otherDictionary];
    [self multipleValuesChanged];
}

- (void)removeAllObjects {
    [_dictionary removeAllObjects];
    [self multipleValuesChanged];
}

- (void)removeObjectsForKeys:(NSArray *)keyArray {
    [_dictionary removeObjectsForKeys:keyArray];
    [self multipleValuesChanged];
}

- (void)setDictionary:(NSDictionary *)otherDictionary {
    [_dictionary setDictionary:otherDictionary];
    [self multipleValuesChanged];
}


@end
