
#import <Foundation/Foundation.h>


@interface NSRegularExpression (P2RegularExpressionExtensions)

- (NSTextCheckingResult *)p2_firstMatchInString:(NSString *)string;
- (NSTextCheckingResult *)p2_firstMatchInString:(NSString *)string options:(NSMatchingOptions)options;

- (NSRange)p2_rangeOfFirstMatchInString:(NSString *)string;
- (NSRange)p2_rangeOfFirstMatchInString:(NSString *)string options:(NSMatchingOptions)options;

- (void)p2_enumerateMatchesInString:(NSString *)string usingBlock:(void (^)(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop))block;
- (void)p2_enumerateMatchesInString:(NSString *)string options:(NSMatchingOptions)options usingBlock:(void (^)(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop))block;

@end


@interface NSString (P2RegularExpressionExtensions)

- (BOOL)p2_matchesRegexp:(NSRegularExpression *)regexp;
- (BOOL)p2_matchesRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options;
- (BOOL)p2_matchesRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)searchRange;

- (NSRange)p2_rangeOfRegexp:(NSRegularExpression *)regexp;
- (NSRange)p2_rangeOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options;
- (NSRange)p2_rangeOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)searchRange;

@end
