
#import <Foundation/Foundation.h>


@interface NSDictionary (SafeAccess)

- (NSString *)safeStringForKey:(NSString *)key;
- (NSArray *)safeArrayForKey:(NSString *)key;

@end
