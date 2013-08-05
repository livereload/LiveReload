
#import <Foundation/Foundation.h>


@interface Bag : NSObject {
@private
    NSMutableDictionary   *_dictionary;
}

@property(nonatomic, readonly, strong) NSDictionary *dictionary;

- (void)removeObjectForKey:(id)aKey;
- (void)setObject:(id)anObject forKey:(id)aKey;

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary;
- (void)removeAllObjects;
- (void)removeObjectsForKeys:(NSArray *)keyArray;
- (void)setDictionary:(NSDictionary *)otherDictionary;

@end
