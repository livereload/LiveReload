
#import <Foundation/Foundation.h>

@interface NSString (ATProperURLEncoding)

- (NSString *)stringByApplyingURLEncoding __deprecated;
- (NSString *)stringByEscapingURLComponent;
- (NSString *)stringByUnescapingURLComponent;

- (void)enumerateURLQueryComponentsUsingBlock:(void (^)(NSString *key, NSString *value))block;
- (NSDictionary *)dictionaryByParsingURLQueryComponents;

@end
