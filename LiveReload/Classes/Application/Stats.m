
#import "Stats.h"

NSString *StatItemKey(NSString *name, NSString *item) {
    return [name stringByAppendingFormat:@".%@", item];
}

void StatIncrement(NSString *name, NSInteger delta) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[defaults integerForKey:name] + delta forKey:name];
    [defaults synchronize];
}

void StatGroupIncrement(NSString *name, NSString *item, NSInteger delta) {
    StatIncrement(name, delta);
    StatIncrement(StatItemKey(name, item), delta);
}

NSArray *StatGroupItems(NSString *name) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [defaults dictionaryRepresentation];
    NSString *prefix = StatItemKey(name, @"");

    NSMutableArray *result = [NSMutableArray array];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([[key substringToIndex:[prefix length]] isEqualToString:prefix]) {
            [result addObject:[key substringFromIndex:[prefix length]]];
        }
    }];
    return [NSArray arrayWithArray:result];
}

NSInteger StatGet(NSString *name) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults integerForKey:name];
}

NSInteger StatGetItem(NSString *name, NSString *item) {
    return StatGet(StatItemKey(name, item));
}

void StatAllToParams(NSMutableDictionary *params) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [defaults dictionaryRepresentation];
    NSString *prefix = @"stat.";

    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([[key substringToIndex:[prefix length]] isEqualToString:prefix]) {
            StatToParams(key, params);
        }
    }];
}

void StatToParams(NSString *name, NSMutableDictionary *params) {
    NSInteger value = StatGet(name);
    [params setObject:[NSString stringWithFormat:@"%ld", value] forKey:name];
}

void StatGroupToParams(NSString *name, NSMutableDictionary *params) {
    StatToParams(name, params);
    for (NSString *item in StatGroupItems(name)) {
        StatToParams(StatItemKey(name, item), params);
    }
}
