
#import "P2RegularExpressionExtensions.h"


static NSRange P2GetFullStringRange(NSString *string) {
    return NSMakeRange(0, string.length);
}


@implementation NSRegularExpression (P2RegularExpressionExtensions)

- (NSTextCheckingResult *)p2_firstMatchInString:(NSString *)string {
    return [self firstMatchInString:string options:0 range:P2GetFullStringRange(string)];
}

- (NSTextCheckingResult *)p2_firstMatchInString:(NSString *)string options:(NSMatchingOptions)options {
    return [self firstMatchInString:string options:options range:P2GetFullStringRange(string)];
}

- (NSRange)p2_rangeOfFirstMatchInString:(NSString *)string {
    return [self rangeOfFirstMatchInString:string options:0 range:P2GetFullStringRange(string)];
}

- (NSRange)p2_rangeOfFirstMatchInString:(NSString *)string options:(NSMatchingOptions)options {
    return [self rangeOfFirstMatchInString:string options:options range:P2GetFullStringRange(string)];
}

- (void)p2_enumerateMatchesInString:(NSString *)string usingBlock:(void (^)(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop))block {
    return [self enumerateMatchesInString:string options:0 range:P2GetFullStringRange(string) usingBlock:block];
}

- (void)p2_enumerateMatchesInString:(NSString *)string options:(NSMatchingOptions)options usingBlock:(void (^)(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop))block {
    return [self enumerateMatchesInString:string options:options range:P2GetFullStringRange(string) usingBlock:block];
}

//- (NSArray *)matchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;
//- (NSUInteger)numberOfMatchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;

@end


@implementation NSString (P2RegularExpressionExtensions)

- (BOOL)p2_matchesRegexp:(NSRegularExpression *)regexp {
    return [self p2_matchesRegexp:regexp options:0];
}
- (BOOL)p2_matchesRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options {
    return [self p2_matchesRegexp:regexp options:options range:P2GetFullStringRange(self)];
}
- (BOOL)p2_matchesRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)searchRange {
    return [regexp firstMatchInString:self options:options range:searchRange];
}

- (NSRange)p2_rangeOfRegexp:(NSRegularExpression *)regexp {
    return [regexp rangeOfFirstMatchInString:self options:0 range:P2GetFullStringRange(self)];
}
- (NSRange)p2_rangeOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options {
    return [regexp rangeOfFirstMatchInString:self options:options range:P2GetFullStringRange(self)];
}
- (NSRange)p2_rangeOfRegexp:(NSRegularExpression *)regexp options:(NSMatchingOptions)options range:(NSRange)searchRange {
    return [regexp rangeOfFirstMatchInString:self options:options range:searchRange];
}

// - (NSArray *)RKL_METHOD_PREPEND(componentsSeparatedByRegex):(NSString *)regex;

// - (NSString *)RKL_METHOD_PREPEND(stringByReplacingOccurrencesOfRegex):(NSString *)regex withString:(NSString *)replacement;
// - (NSString *)RKL_METHOD_PREPEND(stringByReplacingOccurrencesOfRegex):(NSString *)regex usingBlock:(NSString *(^)(NSInteger captureCount, NSString * const capturedStrings[captureCount], const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;

// - (NSArray *)RKL_METHOD_PREPEND(componentsMatchedByRegex):(NSString *)regex;
// - (NSArray *)RKL_METHOD_PREPEND(captureComponentsMatchedByRegex):(NSString *)regex;
// - (NSArray *)RKL_METHOD_PREPEND(arrayOfCaptureComponentsMatchedByRegex):(NSString *)regex;
// - (NSArray *)RKL_METHOD_PREPEND(arrayOfDictionariesByMatchingRegex):(NSString *)regex withKeysAndCaptures:(id)firstKey, ... RKL_REQUIRES_NIL_TERMINATION;
// - (NSDictionary *)RKL_METHOD_PREPEND(dictionaryByMatchingRegex):(NSString *)regex withKeysAndCaptures:(id)firstKey, ... RKL_REQUIRES_NIL_TERMINATION;

@end


//@interface NSMutableString (RegexKitLiteAdditions)

// - (NSInteger)RKL_METHOD_PREPEND(replaceOccurrencesOfRegex):(NSString *)regex withString:(NSString *)replacement;
// - (NSInteger)RKL_METHOD_PREPEND(replaceOccurrencesOfRegex):(NSString *)regex usingBlock:(NSString *(^)(NSInteger captureCount, NSString * const capturedStrings[captureCount], const NSRange capturedRanges[captureCount], volatile BOOL * const stop))block;

//@end