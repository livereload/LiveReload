
#import "ATPathSpec.h"
#import "ATPathSpecPrivate.h"
#import "RegexKitLite.h"


NSString *const ATPathSpecErrorDomain = @"ATPathSpecErrorDomain";
NSString *const ATPathSpecErrorSpecStringKey = @"ATPathSpecErrorSpecString";


NSString *const ATPathSpecMatchInfoMatchedSuffix = @"MatchedSuffix";
NSString *const ATPathSpecMatchInfoMatchedStaticName = @"MatchedStaticName";


static NSString *ATPathSpecTokenTypeNames[] = {
    @"NONE",
    @"Mask",
    @"!",
    @";",
    @",",
    @"_",
    @"|",
    @"&",
    @"(",
    @")",
};


#define return_error(returnValue, outError, error)  do { \
        if (outError) *outError = error; \
        return nil; \
    } while(0)


NSString *ATPathSpec_Unescape(NSString *string) {
    static NSCharacterSet *escapes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        escapes = [NSCharacterSet characterSetWithCharactersInString:@"\\"];
    });

    NSRange range = [string rangeOfCharacterFromSet:escapes];
    if (range.location == NSNotFound)
        return string;

    NSUInteger srclen = string.length;
    unichar source[srclen];
    [string getCharacters:source range:NSMakeRange(0, srclen)];

    unichar result[srclen];
    NSUInteger reslen = 0;

    for (unichar *srcend = source + srclen, *psrc = source; psrc < srcend; ++psrc) {
        unichar ch = *psrc;
        if (ch == '\\') {
            ++psrc;
            if (psrc < srcend)
                result[reslen++] = *psrc;
        } else {
            result[reslen++] = ch;
        }
    }

    return [NSString stringWithCharacters:result length:reslen];
}

NSString *ATPathSpec_Escape(NSString *string, NSCharacterSet *characterSet) {
    NSRange range = [string rangeOfCharacterFromSet:characterSet];
    if (range.location == NSNotFound)
        return string;

    NSUInteger srclen = string.length;
    unichar source[srclen];
    [string getCharacters:source range:NSMakeRange(0, srclen)];

    unichar result[srclen * 2];
    NSUInteger reslen = 0;

    for (unichar *srcend = source + srclen, *psrc = source; psrc < srcend; ++psrc) {
        unichar ch = *psrc;
        if ([characterSet characterIsMember:ch]) {
            result[reslen++] = '\\';
        }
        result[reslen++] = ch;
    }

    return [NSString stringWithCharacters:result length:reslen];
}

NSString *ATPathSpec_StringByEscapingRegex(NSString *regex) {
    return [regex stringByReplacingOccurrencesOfRegex:@"([\\\\.^$\\[|*+?\\{])" withString:@"\\\\$1"];
}

NSString *ATPathSpec_RegexFromPatternString(NSString *pattern, ATPathSpecSyntaxOptions options) {
    BOOL star = !!(options & ATPathSpecSyntaxOptionsAllowStarWildcard);
    BOOL question = !!(options & ATPathSpecSyntaxOptionsAllowQuestionMarkWildcard);
    if (star)
        pattern = [pattern stringByReplacingOccurrencesOfString:@"*" withString:@"_@,STAR,@_"];
    if (question)
        pattern = [pattern stringByReplacingOccurrencesOfString:@"?" withString:@"_@,DOT,@_"];
    NSString *regex = ATPathSpec_StringByEscapingRegex(pattern);
    if (star)
        regex = [regex stringByReplacingOccurrencesOfString:@"_@,DOT,@_" withString:@"."];
    if (question)
        regex = [regex stringByReplacingOccurrencesOfString:@"_@,STAR,@_" withString:@".*"];
    return [NSString stringWithFormat:@"^%@$", regex];
}

NSString *ATPathSpec_StaticSuffixFromPatternString(NSString *pattern, ATPathSpecSyntaxOptions options) {
    BOOL star = !!(options & ATPathSpecSyntaxOptionsAllowStarWildcard);
    BOOL question = !!(options & ATPathSpecSyntaxOptionsAllowQuestionMarkWildcard);

    if (!star)
        return nil;

    NSRange range = [pattern rangeOfString:@"*" options:NSBackwardsSearch];
    if (range.location == NSNotFound)
        return nil;

    NSString *candidate = [pattern substringFromIndex:range.location + range.length];
    if (candidate.length == 0)
        return nil;

    if (question && [candidate rangeOfString:@"?"].location != NSNotFound)
        return nil;

    return candidate;
}

NSString *ATPathSpecAdjustTrailingSlash(NSString *path, ATPathSpecEntryType type) {
    if (type == ATPathSpecEntryTypeFolder)
        return ATPathSpecAddTrailingSlash(path);
    else
        return ATPathSpecRemoveTrailingSlash(path);
}

NSString *ATPathSpecAddTrailingSlash(NSString *path) {
    if (![path hasSuffix:@"/"])
        return [path stringByAppendingString:@"/"];
    else
        return path;
}

NSString *ATPathSpecRemoveTrailingSlash(NSString *path) {
    while ([path hasSuffix:@"/"])
        path = [path substringToIndex:path.length - 1];
    return path;
}

BOOL ATPathSpecEntryType_Match(ATPathSpecEntryType required, ATPathSpecEntryType actual) {
    if (required == ATPathSpecEntryTypeFileOrFolder || actual == ATPathSpecEntryTypeFileOrFolder)
        return YES;
    return required == actual;
}

NSString *ATPathSpecSyntaxOptions_QuoteIfNeeded(NSString *string, ATPathSpecSyntaxOptions options) {
    if (!(options & ATPathSpecSyntaxOptionsAllowBackslashEscape))
        return string;

    NSMutableCharacterSet *specialCharacters = [NSMutableCharacterSet new];
    [specialCharacters addCharactersInString:@"\\"];
    if (options & ATPathSpecSyntaxOptionsAllowNewlineSeparator)
        [specialCharacters formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
    if (options & ATPathSpecSyntaxOptionsAllowCommaSeparator)
        [specialCharacters addCharactersInString:@","];
    if (options & ATPathSpecSyntaxOptionsAllowWhitespaceSeparator)
        [specialCharacters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    if (options & ATPathSpecSyntaxOptionsAllowPipeUnion)
        [specialCharacters addCharactersInString:@"|"];
    if (options & ATPathSpecSyntaxOptionsAllowAmpersandIntersection)
        [specialCharacters addCharactersInString:@"&"];
    if (options & ATPathSpecSyntaxOptionsAllowParen)
        [specialCharacters addCharactersInString:@"()"];
    if (options & ATPathSpecSyntaxOptionsAllowHashComment)
        [specialCharacters addCharactersInString:@"#"];
    if (options & ATPathSpecSyntaxOptionsAllowBangNegation)
        [specialCharacters addCharactersInString:@"!"];
    return ATPathSpec_Escape(string, specialCharacters);
}

NSString *ATPathSpecSyntaxOptions_UnquoteIfNeeded(NSString *string, ATPathSpecSyntaxOptions options) {
    if (!(options & ATPathSpecSyntaxOptionsAllowBackslashEscape))
        return string;
    return ATPathSpec_Unescape(string);
}


#pragma mark -

@implementation ATMask

+ (ATMask *)maskWithString:(NSString *)string syntaxOptions:(ATPathSpecSyntaxOptions)options {
    BOOL star = !!(options & ATPathSpecSyntaxOptionsAllowStarWildcard);
    BOOL question = !!(options & ATPathSpecSyntaxOptionsAllowQuestionMarkWildcard);
    if (!star && !question)
        return [[ATLiteralMask alloc] initWithName:string];

    NSCharacterSet *wildcards = [NSCharacterSet characterSetWithCharactersInString:@"*?"];

    NSUInteger wildcardPos = [string rangeOfCharacterFromSet:wildcards].location;
    if (wildcardPos == NSNotFound) {
        return [[ATLiteralMask alloc] initWithName:string];
    } else {
        if (star && wildcardPos == 0 && [string characterAtIndex:0] == '*') {
            NSString *suffix = [string substringFromIndex:1];
            if ([suffix rangeOfCharacterFromSet:wildcards].location == NSNotFound) {
                return [[ATSuffixMask alloc] initWithSuffix:suffix];
            }
        }
        return [[ATPatternMask alloc] initWithPattern:string syntaxOptions:options];
    }
}

- (BOOL)matchesName:(NSString *)name matchInfo:(NSDictionary **)matchInfo {
    abort();
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    abort();
}

- (NSString *)description {
    return [self stringRepresentationWithSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
}

@end


#pragma mark -

@implementation ATLiteralMask

@synthesize name = _name;

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
    }
    return self;
}

- (BOOL)matchesName:(NSString *)name matchInfo:(NSDictionary **)matchInfo {
    if ([_name isEqualToString:name]) {
        if (matchInfo)
            *matchInfo = @{ATPathSpecMatchInfoMatchedStaticName: _name};
        return YES;
    }
    return NO;
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    return ATPathSpecSyntaxOptions_QuoteIfNeeded(_name, options);
}

@end


@implementation ATSuffixMask

@synthesize suffix=_suffix;

- (id)initWithSuffix:(NSString *)suffix {
    self = [super init];
    if (self) {
        _suffix = [suffix copy];
    }
    return self;
}

- (BOOL)matchesName:(NSString *)name matchInfo:(NSDictionary **)matchInfo {
    NSUInteger nameLen = name.length, suffixLen = _suffix.length;
    if (nameLen < _suffix.length || NSOrderedSame != [name compare:_suffix options:NSLiteralSearch range:NSMakeRange(nameLen - suffixLen, suffixLen)])
        return NO;

    if (matchInfo)
        *matchInfo = @{ATPathSpecMatchInfoMatchedSuffix: _suffix};
    return YES;
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    return ATPathSpecSyntaxOptions_QuoteIfNeeded([NSString stringWithFormat:@"*%@", _suffix], options);
}

@end


@implementation ATPatternMask {
    NSString *_regex;
    NSString *_staticSuffix;
}

@synthesize pattern = _pattern;

- (id)initWithPattern:(NSString *)pattern syntaxOptions:(ATPathSpecSyntaxOptions)options {
    self = [super init];
    if (self) {
        _pattern = [pattern copy];
        _regex = ATPathSpec_RegexFromPatternString(_pattern, options);
        _staticSuffix = ATPathSpec_StaticSuffixFromPatternString(_pattern, options);
    }
    return self;
}

- (BOOL)matchesName:(NSString *)name matchInfo:(NSDictionary **)matchInfo {
    if ([name isMatchedByRegex:_regex]) {
        if (matchInfo) {
            if (_staticSuffix)
                *matchInfo = @{ATPathSpecMatchInfoMatchedSuffix: _staticSuffix};
            else
                *matchInfo = @{};
        }
        return YES;
    }
    return NO;
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    return ATPathSpecSyntaxOptions_QuoteIfNeeded(_pattern, options);
}

@end


#pragma mark -

@implementation ATPathSpec (ATPathSpecPrivate)

+ (void)enumerateTokensInString:(NSString *)string withSyntaxOptions:(ATPathSpecSyntaxOptions)options usingBlock:(ATPathSpecTokenBlock)block decodeTokens:(BOOL)decodeTokens {
    BOOL escapeEnabled = !!(options & ATPathSpecSyntaxOptionsAllowBackslashEscape);
    BOOL negationEnabled = !!(options & ATPathSpecSyntaxOptionsAllowBangNegation);

    NSCharacterSet *escapeCharacters = escapeEnabled ? [NSCharacterSet characterSetWithCharactersInString:@"\\"] : [NSCharacterSet new];
    NSCharacterSet *whitespaceCharacters = [NSCharacterSet whitespaceCharacterSet];
    NSCharacterSet *newlineCharacters = [NSCharacterSet newlineCharacterSet];

    NSMutableCharacterSet *specialCharacters = [NSMutableCharacterSet new];
    [specialCharacters formUnionWithCharacterSet:escapeCharacters];
    if (options & ATPathSpecSyntaxOptionsAllowNewlineSeparator)
        [specialCharacters addCharactersInString:@"\n"];
    if (options & ATPathSpecSyntaxOptionsAllowCommaSeparator)
        [specialCharacters addCharactersInString:@","];
    if (options & ATPathSpecSyntaxOptionsAllowWhitespaceSeparator)
        [specialCharacters formUnionWithCharacterSet:whitespaceCharacters];
    if (options & ATPathSpecSyntaxOptionsAllowPipeUnion)
        [specialCharacters addCharactersInString:@"|"];
    if (options & ATPathSpecSyntaxOptionsAllowAmpersandIntersection)
        [specialCharacters addCharactersInString:@"&"];
    if (options & ATPathSpecSyntaxOptionsAllowParen)
        [specialCharacters addCharactersInString:@"()"];
    if (options & ATPathSpecSyntaxOptionsAllowHashComment)
        [specialCharacters addCharactersInString:@"#"];

    // don't include unary operators ("!") into the specialCharacters because they have no special meaning unless they start the mask

    NSUInteger len = string.length;
    unichar buffer[len];
    [string getCharacters:buffer range:NSMakeRange(0, len)];

    ATPathSpecTokenType lastTokenType = ATPathSpecTokenTypeNone;
    ATPathSpecTokenType queuedTokenType = ATPathSpecTokenTypeNone;
    NSRange queuedTokenRange;
    NSUInteger textTokenStart = 0;
    NSUInteger searchStart = textTokenStart;
    while (textTokenStart < len) {
        NSUInteger specialPos = (searchStart >= len ? NSNotFound : [string rangeOfCharacterFromSet:specialCharacters options:0 range:NSMakeRange(searchStart, len - searchStart)].location);

        // skip the escape sequence
        if (escapeEnabled && specialPos != NSNotFound && [escapeCharacters characterIsMember:buffer[specialPos]]) {
            searchStart = specialPos + 2;  // don't interpret the next character as a special operator
            continue;
        }

        NSUInteger textTokenEnd = (specialPos == NSNotFound ? len : specialPos);

        // handle unary operators (and leading whitespace)
        while (textTokenStart < textTokenEnd) {
            // skip leading whitespace
            while (textTokenStart < textTokenEnd && [whitespaceCharacters characterIsMember:buffer[textTokenStart]])
                ++textTokenStart;

            // unary operators
            if (negationEnabled && buffer[textTokenStart] == '!') {
                if (queuedTokenType != ATPathSpecTokenTypeNone) {
                    block(queuedTokenType, queuedTokenRange, nil);
                    queuedTokenType = ATPathSpecTokenTypeNone;
                }
                block(ATPathSpecTokenTypeNegation, NSMakeRange(textTokenStart, 1), nil);
                lastTokenType = ATPathSpecTokenTypeNegation;
                ++textTokenStart;
            } else {
                break;
            }
        }

        // skip trailing whitespace
        while (textTokenStart < textTokenEnd && [whitespaceCharacters characterIsMember:buffer[textTokenEnd - 1]])
            --textTokenEnd;

        // handle regular text
        if (textTokenStart < textTokenEnd) {
            NSRange textTokenRange = NSMakeRange(textTokenStart, textTokenEnd - textTokenStart);
            NSString *textTokenString = nil;
            if (decodeTokens) {
                textTokenString = ATPathSpec_Unescape([[string substringWithRange:textTokenRange] stringByTrimmingCharactersInSet:whitespaceCharacters]);
            }
            if (queuedTokenType != ATPathSpecTokenTypeNone) {
                block(queuedTokenType, queuedTokenRange, nil);
                queuedTokenType = ATPathSpecTokenTypeNone;
            }
            block(ATPathSpecTokenTypeMask, textTokenRange, textTokenString);
            lastTokenType = ATPathSpecTokenTypeMask;
        }

        if (specialPos == NSNotFound)
            return;

        unichar special = buffer[specialPos];
        if (special == '#') {
            // skip comment
            NSUInteger eol = [string rangeOfCharacterFromSet:newlineCharacters options:0 range:NSMakeRange(specialPos+1, len - (specialPos+1))].location;
            if (eol == NSNotFound) {
                eol = len;
            } else {
                if (lastTokenType != ATPathSpecTokenTypeNone && queuedTokenType != ATPathSpecTokenTypeNewline) {
                    queuedTokenType = ATPathSpecTokenTypeNewline;
                    queuedTokenRange = NSMakeRange(eol, 1);
                }
            }
            textTokenStart = searchStart = eol + 1;
        } else if ([whitespaceCharacters characterIsMember:special]) {
            if (queuedTokenType != ATPathSpecTokenTypeNewline && queuedTokenType != ATPathSpecTokenTypeComma && queuedTokenType != ATPathSpecTokenTypeWhitespace && (lastTokenType == ATPathSpecTokenTypeMask || lastTokenType == ATPathSpecTokenTypeCloseParen) ) {
                queuedTokenType = ATPathSpecTokenTypeWhitespace;
                queuedTokenRange = NSMakeRange(specialPos, 1);
            }

            // skip remaining whitespace
            searchStart = specialPos + 1;
            while (searchStart < len && [whitespaceCharacters characterIsMember:buffer[searchStart]])
                ++searchStart;
            textTokenStart = searchStart;
        } else {
            textTokenStart = searchStart = specialPos + 1;

            ATPathSpecTokenType type = ATPathSpecTokenTypeNone;
            switch (special) {
                case '\n':
                    if (lastTokenType != ATPathSpecTokenTypeNone && queuedTokenType != ATPathSpecTokenTypeNewline) {
                        queuedTokenType = ATPathSpecTokenTypeNewline;
                        queuedTokenRange = NSMakeRange(specialPos, 1);
                    }
                    break;
                case ',':
                    if (queuedTokenType != ATPathSpecTokenTypeNewline && queuedTokenType != ATPathSpecTokenTypeComma) {
                        queuedTokenType = ATPathSpecTokenTypeComma;
                        queuedTokenRange = NSMakeRange(specialPos, 1);
                    }
                    break;
                case '|':
                    queuedTokenType = ATPathSpecTokenTypeNone;
                    type = ATPathSpecTokenTypeUnion;
                    break;
                case '&':
                    queuedTokenType = ATPathSpecTokenTypeNone;
                    type = ATPathSpecTokenTypeIntersection;
                    break;
                case '(':
                    type = ATPathSpecTokenTypeOpenParen;
                    break;
                case ')':
                    queuedTokenType = ATPathSpecTokenTypeNone;
                    type = ATPathSpecTokenTypeCloseParen;
                    break;
                default:
                    abort();
            }
            if (type != ATPathSpecTokenTypeNone) {
                if (queuedTokenType != ATPathSpecTokenTypeNone) {
                    block(queuedTokenType, queuedTokenRange, nil);
                    queuedTokenType = ATPathSpecTokenTypeNone;
                }
                block(type, NSMakeRange(specialPos, 1), nil);
                lastTokenType = type;
            }
        }
    }
}

+ (NSString *)describeTokensInString:(NSString *)string withSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    NSMutableArray *description = [NSMutableArray new];
    [self enumerateTokensInString:string withSyntaxOptions:options usingBlock:^(ATPathSpecTokenType type, NSRange range, NSString *decoded) {
        if (type == ATPathSpecTokenTypeMask)
            [description addObject:[NSString stringWithFormat:@"Mask(%@)", decoded]];
        else
            [description addObject:ATPathSpecTokenTypeNames[type]];
    } decodeTokens:YES];
    return [description componentsJoinedByString:@" "];
}

- (BOOL)isComplexExpression {
    return NO;
}

- (NSString *)parenthesizedStringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    NSString *repr = [self stringRepresentationWithSyntaxOptions:options];
    if ([self isComplexExpression])
        return [NSString stringWithFormat:@"(%@)", repr];
    else
        return repr;
}

@end


@implementation ATPathSpec

+ (ATPathSpec *)pathSpecWithString:(NSString *)string syntaxOptions:(ATPathSpecSyntaxOptions)options {
    NSError *error = nil;
    ATPathSpec *result = [self pathSpecWithString:string syntaxOptions:options error:&error];
    if (!result) {
        NSAssert(NO, @"Error in [ATPathSpec pathSpecWithString:\"%@\"]: %@", string, error.localizedDescription);
        abort();
    }
    return result;
}

+ (ATPathSpec *)pathSpecWithString:(NSString *)string syntaxOptions:(ATPathSpecSyntaxOptions)options error:(NSError **)outError {
    NSMutableArray *contexts = [NSMutableArray new];
    __block NSMutableArray *specs = [NSMutableArray new];
    __block ATPathSpecTokenType op = ATPathSpecTokenTypeNone;
    __block BOOL nextNegated = NO;
    __block BOOL lastNegated = NO;

    __block BOOL failed = NO;

    ATPathSpec *(^flushContext)() = ^ATPathSpec *{
        if (specs.count == 0) {
            if (outError)
                *outError = nil;
            return nil;
        }
        if (specs.count == 1) {
            return [specs firstObject];
        }
        switch (op) {
            case ATPathSpecTokenTypeNone:
                NSAssert(specs.count <= 1, @"Multiple specs cannot be added without an operator");
                abort();
            case ATPathSpecTokenTypeUnion:
                return [ATPathSpec pathSpecMatchingUnionOf:specs];
            case ATPathSpecTokenTypeIntersection:
                return [ATPathSpec pathSpecMatchingIntersectionOf:specs];
            case ATPathSpecTokenTypeComma:
                if (lastNegated)
                    return [ATPathSpec pathSpecMatchingIntersectionOf:specs];
                else
                    return [ATPathSpec pathSpecMatchingUnionOf:specs];
            default:
                abort();
        }
    };
    
    void (^addSpec)(ATPathSpec *spec) = ^(ATPathSpec *spec){
        if (op == ATPathSpecTokenTypeComma && specs.count > 1 && nextNegated != lastNegated) {
            // a b !c d -> ((a | b) & !c) | d, so we need to flush when switching between negated and non-negated patterns
            ATPathSpec *other = flushContext();
            [specs removeAllObjects];
            [specs addObject:other];
        }
        lastNegated = nextNegated;
        if (nextNegated) {
            spec = [spec negatedPathSpec];
        }
        [specs addObject:spec];
        nextNegated = NO;
    };

    void (^initContext)() = ^{
        specs = [NSMutableArray new];
        op = ATPathSpecTokenTypeNone;
        lastNegated = nextNegated = NO;
    };

    void (^pushContext)() = ^{
        [contexts addObject:@{@"specs": specs, @"op": @(op), @"nextNegated": @(nextNegated), @"lastNegated": @(lastNegated)}];
        initContext();
    };

    void (^popContext)() = ^{
        ATPathSpec *spec = flushContext();

        NSDictionary *c = [contexts lastObject];
        [contexts removeLastObject];

        specs = c[@"specs"];
        op = [c[@"op"] unsignedIntValue];
        nextNegated = [c[@"nextNegated"] boolValue];
        lastNegated = [c[@"lastNegated"] boolValue];

        if (spec)
            addSpec(spec);
    };

    [ATPathSpec enumerateTokensInString:string withSyntaxOptions:options usingBlock:^(ATPathSpecTokenType type, NSRange range, NSString *decoded) {
        if (failed)
            return;
        if (type == ATPathSpecTokenTypeMask) {
            ATPathSpec *spec = [self pathSpecWithSingleMaskString:decoded syntaxOptions:options error:outError];
            if (!spec) {
                failed = YES;
                return;
            }
            addSpec(spec);
        } else if (type == ATPathSpecTokenTypeWhitespace || type == ATPathSpecTokenTypeComma || type == ATPathSpecTokenTypeNewline) {
            if (op != ATPathSpecTokenTypeNone && op != ATPathSpecTokenTypeComma) {
                if (outError)
                    *outError = [NSError errorWithDomain:ATPathSpecErrorDomain code:ATPathSpecErrorCodeInvalidSpecString userInfo:@{ATPathSpecErrorSpecStringKey: string, NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Cannot mix different operators without parens: '%@'", string]}];
                failed = YES;
                return;
            }
            op = ATPathSpecTokenTypeComma;
        } else if (type == ATPathSpecTokenTypeNegation) {
            nextNegated = !nextNegated;
        } else if (type == ATPathSpecTokenTypeUnion) {
            if (op != ATPathSpecTokenTypeNone && op != ATPathSpecTokenTypeUnion) {
                if (outError)
                    *outError = [NSError errorWithDomain:ATPathSpecErrorDomain code:ATPathSpecErrorCodeInvalidSpecString userInfo:@{ATPathSpecErrorSpecStringKey: string, NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Cannot mix different operators without parens: '%@'", string]}];
                failed = YES;
                return;
            }
            op = ATPathSpecTokenTypeUnion;
        } else if (type == ATPathSpecTokenTypeIntersection) {
            if (op != ATPathSpecTokenTypeNone && op != ATPathSpecTokenTypeIntersection) {
                if (outError)
                    *outError = [NSError errorWithDomain:ATPathSpecErrorDomain code:ATPathSpecErrorCodeInvalidSpecString userInfo:@{ATPathSpecErrorSpecStringKey: string, NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Cannot mix different operators without parens: '%@'", string]}];
                failed = YES;
                return;
            }
            op = ATPathSpecTokenTypeIntersection;
        } else if (type == ATPathSpecTokenTypeOpenParen) {
            pushContext();
        } else if (type == ATPathSpecTokenTypeCloseParen) {
            if (contexts.count == 0) {
                if (outError)
                    *outError = [NSError errorWithDomain:ATPathSpecErrorDomain code:ATPathSpecErrorCodeInvalidSpecString userInfo:@{ATPathSpecErrorSpecStringKey: string, NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Unmatched close paren: '%@'", string]}];
                failed = YES;
                return;
            }
            popContext();
        } else {
            abort();
        }
    } decodeTokens:YES];

    if (contexts.count > 0) {
        if (outError)
            *outError = [NSError errorWithDomain:ATPathSpecErrorDomain code:ATPathSpecErrorCodeInvalidSpecString userInfo:@{ATPathSpecErrorSpecStringKey: string, NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Unmatched open paren: '%@'", string]}];
        failed = YES;
    }

    if (failed)
        return nil;

    if (specs.count == 0)
        return [ATPathSpec emptyPathSpec];

    return flushContext();
}

+ (ATPathSpec *)pathSpecWithSingleMaskString:(NSString *)originalString syntaxOptions:(ATPathSpecSyntaxOptions)options error:(NSError **)outError {
    NSString *string = originalString;
    NSUInteger len = string.length;
    if (len == 0)
        return [ATPathSpec emptyPathSpec];

    ATPathSpecEntryType type = (options & ATPathSpecSyntaxOptionsRequireTrailingSlashForFolders ? ATPathSpecEntryTypeFile : ATPathSpecEntryTypeFileOrFolder);
    if ([string characterAtIndex:len - 1] == '/') {
        type = ATPathSpecEntryTypeFolder;
        string = [string substringToIndex:len - 1];
        --len;
    }

    NSArray *components = [string pathComponents];

    if ((options & ATPathSpecSyntaxOptionsMatchesAnyFolderWhenNoPathSpecified) && (components.count == 1)) {
        // no path specified => matches this name in any subfolder
        ATMask *mask = [ATMask maskWithString:string syntaxOptions:options];
        return [self pathSpecMatchingNameMask:mask type:type syntaxOptions:options];
    } else {
        // strip leading slash
        if ([components[0] isEqualToString:@"/"])
            components = [components subarrayWithRange:NSMakeRange(1, components.count - 1)];

        NSMutableArray *masks = [NSMutableArray new];
        for (NSString *component in components) {
            ATMask *mask = [ATMask maskWithString:component syntaxOptions:options];
            [masks addObject:mask];
        }

        return [self pathSpecMatchingPathMasks:masks type:type syntaxOptions:options];
    }
}

+ (ATPathSpec *)pathSpecMatchingNameMask:(ATMask *)mask type:(ATPathSpecEntryType)type syntaxOptions:(ATPathSpecSyntaxOptions)options {
    return [[ATNameMaskPathSpec alloc] initWithMask:mask type:type syntaxOptions:options];
}

+ (ATPathSpec *)pathSpecMatchingPathMasks:(NSArray *)masks type:(ATPathSpecEntryType)type syntaxOptions:(ATPathSpecSyntaxOptions)options {
    return [[ATPathMasksPathSpec alloc] initWithMasks:masks type:type syntaxOptions:ATPathSpecSyntaxOptionsFolderMatchesAllFilesInSubtree];
}

+ (ATPathSpec *)pathSpecMatchingPath:(NSString *)path type:(ATPathSpecEntryType)type syntaxOptions:(ATPathSpecSyntaxOptions)options {
    NSArray *components = [path pathComponents];
    NSMutableArray *masks = [NSMutableArray new];
    for (NSString *component in components) {
        ATMask *mask = [ATMask maskWithString:component syntaxOptions:ATPathSpecSyntaxFlavorLiteral];
        [masks addObject:mask];
    }

    return [self pathSpecMatchingPathMasks:masks type:type syntaxOptions:options];
}

- (BOOL)matchesPath:(NSString *)path type:(ATPathSpecEntryType)type {
    return [self matchResultForPath:path type:type matchInfo:NULL] == ATPathSpecMatchResultMatched;
}

- (ATPathSpecMatchResult)matchResultForPath:(NSString *)path type:(ATPathSpecEntryType)type matchInfo:(NSDictionary **)matchInfo {
    abort();
}

- (NSDictionary *)matchInfoForPath:(NSString *)path type:(ATPathSpecEntryType)type {
    NSDictionary *result;
    if ([self matchResultForPath:path type:type matchInfo:&result] == ATPathSpecMatchResultMatched)
        return result;
    else
        return nil;
}

- (ATPathSpec *)negatedPathSpec {
    return [[ATNegatedPathSpec alloc] initWithSpec:self];
}

+ (ATPathSpec *)emptyPathSpec {
    static ATPathSpec *emptyPathSpec;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        emptyPathSpec = [[ATEmptyPathSpec alloc] init];
    });
    return emptyPathSpec;
}

+ (ATPathSpec *)pathSpecMatchingUnionOf:(NSArray *)specs {
    return [[ATUnionPathSpec alloc] initWithSpecs:specs];
}

+ (ATPathSpec *)pathSpecMatchingIntersectionOf:(NSArray *)specs {
    return [[ATIntersectionPathSpec alloc] initWithSpecs:specs];
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    abort();
}

- (NSString *)description {
    return [self stringRepresentationWithSyntaxOptions:ATPathSpecSyntaxFlavorExtended];
}

- (NSArray *)matchingPathsInArray:(NSArray *)paths type:(ATPathSpecEntryType)type {
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:paths.count];
    for (NSString *path in paths) {
        if ([self matchesPath:path type:type])
            [result addObject:path];
    }
    return [result copy];
}

@end


#pragma mark -

@implementation ATEmptyPathSpec : ATPathSpec

- (ATPathSpecMatchResult)matchResultForPath:(NSString *)path type:(ATPathSpecEntryType)type matchInfo:(NSDictionary **)matchInfo {
    return NO;
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    if (!!(options & ATPathSpecSyntaxOptionsAllowParen))
        return @"()";
    else
        return @"__emptyPathSpec__";

}

- (BOOL)isComplexExpression {
    return NO;
}

@end


#pragma mark -

@implementation ATNameMaskPathSpec {
    BOOL _fuzzyEnabled;
}

@synthesize mask = _mask;
@synthesize type = _type;

- (id)initWithMask:(ATMask *)mask type:(ATPathSpecEntryType)type syntaxOptions:(ATPathSpecSyntaxOptions)options {
    self = [super init];
    if (self) {
        _mask = mask;
        _type = type;
        _fuzzyEnabled = !!(options & ATPathSpecSyntaxOptionsFolderMatchesAllFilesInSubtree);
    }
    return self;
}

- (ATPathSpecMatchResult)matchResultForPath:(NSString *)path type:(ATPathSpecEntryType)type matchInfo:(NSDictionary **)matchInfo {
    if (_fuzzyEnabled && (_type == ATPathSpecEntryTypeFolder || _type == ATPathSpecEntryTypeFileOrFolder)) {
        NSArray *components = path.pathComponents;
        components = [components subarrayWithRange:NSMakeRange(0, components.count - 1)];
        for (NSString *component in components) {
            if ([_mask matchesName:component matchInfo:NULL]) {
                if (matchInfo)
                    *matchInfo = @{};
                return ATPathSpecMatchResultMatched;
            }
        }
    }

    if (!ATPathSpecEntryType_Match(_type, type))
        return ATPathSpecMatchResultUnknown;

    if ([_mask matchesName:[path lastPathComponent] matchInfo:matchInfo])
        return ATPathSpecMatchResultMatched;
    else
        return ATPathSpecMatchResultUnknown;
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    return ATPathSpecAdjustTrailingSlash([_mask stringRepresentationWithSyntaxOptions:options], _type);
}

- (BOOL)isComplexExpression {
    return NO;
}

@end


#pragma mark -

@implementation ATPathMasksPathSpec {
    BOOL _fuzzyEnabled;
}

@synthesize masks = _masks;
@synthesize type = _type;

- (id)initWithMasks:(NSArray *)masks type:(ATPathSpecEntryType)type syntaxOptions:(ATPathSpecSyntaxOptions)options {
    self = [super init];
    if (self) {
        _masks = [masks copy];
        _type = type;
        _fuzzyEnabled = !!(options & ATPathSpecSyntaxOptionsFolderMatchesAllFilesInSubtree);
    }
    return self;
}

- (ATPathSpecMatchResult)matchResultForPath:(NSString *)path type:(ATPathSpecEntryType)type matchInfo:(NSDictionary **)matchInfo {
    BOOL fuzzy = (_fuzzyEnabled && (_type == ATPathSpecEntryTypeFolder || _type == ATPathSpecEntryTypeFileOrFolder));
    BOOL typesCompatible = ATPathSpecEntryType_Match(_type, type);

    if (!typesCompatible && !fuzzy)
        return ATPathSpecMatchResultUnknown;

    NSArray *components = path.pathComponents;
    if ([components[0] isEqualToString:@"/"])
        components = [components subarrayWithRange:NSMakeRange(1, components.count - 1)];

    NSUInteger pcount = components.count;
    NSUInteger mcount = _masks.count;

    if (pcount < mcount)
        return ATPathSpecMatchResultUnknown;
    if (!fuzzy && pcount != mcount)
        return ATPathSpecMatchResultUnknown;
    if (fuzzy && !typesCompatible && pcount == mcount)
        return ATPathSpecMatchResultUnknown; // full match not possible because the entry types are different

    NSInteger index = 0;
    for (ATMask *mask in _masks) {
        NSString *component = components[index++];

        if (![mask matchesName:component matchInfo:(index == pcount ? matchInfo : NULL)])
            return ATPathSpecMatchResultUnknown;
    }

    if (matchInfo && index < pcount)
        *matchInfo = @{};

    return ATPathSpecMatchResultMatched;
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    NSMutableArray *strings = [NSMutableArray new];
    if (_masks.count == 1)
        [strings addObject:@""]; // to prefix with a slash
    for (ATMask *mask in _masks) {
        [strings addObject:[mask stringRepresentationWithSyntaxOptions:options]];
    }
    return ATPathSpecAdjustTrailingSlash([strings componentsJoinedByString:@"/"], _type);
}

- (BOOL)isComplexExpression {
    return NO;
}

@end


#pragma mark -

@implementation ATNegatedPathSpec

@synthesize spec = _spec;

- (id)initWithSpec:(ATPathSpec *)spec {
    self = [super init];
    if (self) {
        _spec = spec;
    }
    return self;
}

- (ATPathSpec *)negatedPathSpec {
    return _spec;
}

- (ATPathSpecMatchResult)matchResultForPath:(NSString *)path type:(ATPathSpecEntryType)type matchInfo:(NSDictionary **)matchInfo {
    if ([_spec matchResultForPath:path type:type matchInfo:NULL] != ATPathSpecMatchResultMatched) {
        if (matchInfo)
            *matchInfo = @{};
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isComplexExpression {
    return NO;
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    return [@"!" stringByAppendingString:[_spec parenthesizedStringRepresentationWithSyntaxOptions:options]];
}

@end


#pragma mark -

@implementation ATUnionPathSpec

@synthesize specs = _specs;

- (id)initWithSpecs:(NSArray *)specs {
    self = [super init];
    if (self) {
        _specs = [specs copy];
    }
    return self;
}

- (ATPathSpecMatchResult)matchResultForPath:(NSString *)path type:(ATPathSpecEntryType)type matchInfo:(NSDictionary **)matchInfo {
    for (ATPathSpec *spec in _specs) {
        ATPathSpecMatchResult result = [spec matchResultForPath:path type:type matchInfo:matchInfo];
        if (result == ATPathSpecMatchResultMatched)
            return ATPathSpecMatchResultMatched;
    }
    return ATPathSpecMatchResultUnknown;
}

- (BOOL)isComplexExpression {
    return YES;
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    NSMutableArray *strings = [NSMutableArray new];
    for (ATPathSpec *spec in _specs) {
        [strings addObject:[spec parenthesizedStringRepresentationWithSyntaxOptions:options]];
    }
    return [strings componentsJoinedByString:@" | "];
}

@end


#pragma mark -

@implementation ATIntersectionPathSpec

@synthesize specs = _specs;

- (id)initWithSpecs:(NSArray *)specs {
    self = [super init];
    if (self) {
        _specs = [specs copy];
    }
    return self;
}

- (ATPathSpecMatchResult)matchResultForPath:(NSString *)path type:(ATPathSpecEntryType)type matchInfo:(NSDictionary **)matchInfo {
    NSDictionary *mergedMatchInfo;
    if (matchInfo)
        mergedMatchInfo = @{};

    for (ATPathSpec *spec in _specs) {
        ATPathSpecMatchResult result;
        if (matchInfo) {
            NSDictionary *itemMatchInfo = nil;
            result = [spec matchResultForPath:path type:type matchInfo:&itemMatchInfo];
            if (result == ATPathSpecMatchResultMatched && itemMatchInfo.count > 0) {
                if (mergedMatchInfo.count == 0) {
                    mergedMatchInfo = itemMatchInfo;
                } else {
                    NSMutableDictionary *mutable = [mergedMatchInfo mutableCopy];
                    [mutable setValuesForKeysWithDictionary:itemMatchInfo];
                    mergedMatchInfo = [mutable copy];
                }
            }
        } else {
            result = [spec matchResultForPath:path type:type matchInfo:NULL];
        }
        if (result != ATPathSpecMatchResultMatched)
            return ATPathSpecMatchResultUnknown;
    }
    
    if (matchInfo)
        *matchInfo = mergedMatchInfo;
    return ATPathSpecMatchResultMatched;
}

- (BOOL)isComplexExpression {
    return YES;
}

- (NSString *)stringRepresentationWithSyntaxOptions:(ATPathSpecSyntaxOptions)options {
    NSMutableArray *strings = [NSMutableArray new];
    for (ATPathSpec *spec in _specs) {
        [strings addObject:[spec parenthesizedStringRepresentationWithSyntaxOptions:options]];
    }
    return [strings componentsJoinedByString:@" & "];
}

@end






