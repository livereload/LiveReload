
#import "ATPathSpec.h"


NSString *ATPathSpec_StringByEscapingRegex(NSString *regex);
NSString *ATPathSpec_RegexFromPatternString(NSString *pattern, ATPathSpecSyntaxOptions options);
BOOL ATPathSpecEntryType_Match(ATPathSpecEntryType required, ATPathSpecEntryType actual);
NSString *ATPathSpecSyntaxOptions_QuoteIfNeeded(NSString *string, ATPathSpecSyntaxOptions options);
NSString *ATPathSpecSyntaxOptions_UnquoteIfNeeded(NSString *string, ATPathSpecSyntaxOptions options);


#pragma mark -


@interface ATLiteralMask : ATMask

- (id)initWithName:(NSString *)name;

@property(nonatomic, readonly) NSString *name;

@end


@interface ATSuffixMask : ATMask

- (id)initWithSuffix:(NSString *)suffix;

@property(nonatomic, readonly) NSString *suffix;

@end


@interface ATPatternMask : ATMask

- (id)initWithPattern:(NSString *)pattern syntaxOptions:(ATPathSpecSyntaxOptions)options;

@property(nonatomic, readonly) NSString *pattern;

@end


#pragma mark -

@interface ATPathSpec (ATPathSpecPrivate)

typedef enum {
    ATPathSpecTokenTypeNone,
    ATPathSpecTokenTypeMask,
    ATPathSpecTokenTypeNegation,
    ATPathSpecTokenTypeNewline,
    ATPathSpecTokenTypeComma,
    ATPathSpecTokenTypeWhitespace,
    ATPathSpecTokenTypeUnion,
    ATPathSpecTokenTypeIntersection,
    ATPathSpecTokenTypeOpenParen,
    ATPathSpecTokenTypeCloseParen,
} ATPathSpecTokenType;

typedef void (^ATPathSpecTokenBlock)(ATPathSpecTokenType type, NSRange range, NSString *decoded);

// spec     -> subspec (operator subspec)*
// operator -> "\n" | "," | "|" | "&"
// subspec  -> mask | "(" spec ")"
+ (void)enumerateTokensInString:(NSString *)string withSyntaxOptions:(ATPathSpecSyntaxOptions)options usingBlock:(ATPathSpecTokenBlock)block decodeTokens:(BOOL)decodeTokens;

+ (NSString *)describeTokensInString:(NSString *)string withSyntaxOptions:(ATPathSpecSyntaxOptions)options;  // for tests and debugging

- (BOOL)isComplexExpression;

- (NSString *)parenthesizedStringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options;

@end


@interface ATEmptyPathSpec : ATPathSpec
@end


@interface ATNameMaskPathSpec : ATPathSpec

- (id)initWithMask:(ATMask *)mask type:(ATPathSpecEntryType)type syntaxOptions:(ATPathSpecSyntaxOptions)options;

@property(nonatomic, readonly) ATMask *mask;
@property(nonatomic, readonly) ATPathSpecEntryType type;

@end


@interface ATPathMasksPathSpec : ATPathSpec

- (id)initWithMasks:(NSArray *)masks type:(ATPathSpecEntryType)type syntaxOptions:(ATPathSpecSyntaxOptions)options;

@property(nonatomic, readonly) NSArray *masks;
@property(nonatomic, readonly) ATPathSpecEntryType type;

@end


@interface ATNegatedPathSpec : ATPathSpec

- (id)initWithSpec:(ATPathSpec *)spec;

@property(nonatomic, readonly) ATPathSpec *spec;

@end


@interface ATUnionPathSpec : ATPathSpec

- (id)initWithSpecs:(NSArray *)specs;

@property(nonatomic, readonly) NSArray *specs;

@end


@interface ATIntersectionPathSpec : ATPathSpec

- (id)initWithSpecs:(NSArray *)specs;

@property(nonatomic, readonly) NSArray *specs;

@end
