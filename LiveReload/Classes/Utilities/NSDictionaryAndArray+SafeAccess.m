
#import "NSDictionaryAndArray+SafeAccess.h"
#import "NSObject+JSON.h"


@implementation NSDictionary (SafeAccess)

- (NSString *)safeStringForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSString class]])
        return obj;
    else
        return nil;
}

- (NSArray *)safeArrayForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:[NSArray class]])
        return obj;
    else if ([obj isKindOfClass:[NSString class]]) {
        id val = [obj JSONValue];
        if ([val isKindOfClass:[NSArray class]])
            return val;
        else
            return nil;
    } else
        return nil;
}


@end
