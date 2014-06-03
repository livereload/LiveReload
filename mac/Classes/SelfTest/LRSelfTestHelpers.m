
#import "LRSelfTestHelpers.h"
#import "ATPathSpec.h"
#import "ATFunctionalStyle.h"
#import "P2RegularExpressionExtensions.h"


BOOL LRSelfTestMatchPath(NSString *pattern, NSString *path) {
    ATPathSpec *spec = [ATPathSpec pathSpecWithString:pattern syntaxOptions:ATPathSpecSyntaxFlavorExtended];
    NSCAssert(!!spec, @"Failed to parse path spec: %@", pattern);
    return [spec matchesPath:path type:ATPathSpecEntryTypeFileOrFolder];
}

BOOL LRSelfTestMatchUnsignedInteger(NSInteger pattern, NSUInteger value) {
    if (pattern == -1)
        return YES;
    return (NSUInteger)pattern == value;
}

BOOL LRSelfTestMatchString(NSString *pattern, NSString *value) {
    NSString *regexpString = [[[pattern componentsSeparatedByString:@"*"] arrayByMappingElementsUsingBlock:^id(NSString *literal) {
        return [NSRegularExpression escapedPatternForString:literal];
    }] componentsJoinedByString:@".*"];
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"^%@$", regexpString] options:NSRegularExpressionCaseInsensitive error:NULL];
    return [regexp p2_matchesString:value];
}

BOOL LRSelfTestMatchUnorderedArrays(NSArray *expectations, NSArray *values, NSString *errorMessage, NSError **outError, LRSelfTestMatchUnorderedArraysMatchBlock matchBlock) {
    NSMutableArray *remainingExpectations = [expectations mutableCopy];
    NSMutableArray *extraValues = [NSMutableArray new];
    for (id value in values) {
        id matchedExpectation = nil;
        for (id expectation in remainingExpectations) {
            if (matchBlock(expectation, value)) {
                matchedExpectation = expectation;
                break;
            }
        }

        if (matchedExpectation) {
            [remainingExpectations removeObject:matchedExpectation];
        } else {
            [extraValues addObject:value];
        }
    }

    if (remainingExpectations.count == 0 && extraValues.count == 0) {
        return YES;
    } else {
        NSString *description = [NSString stringWithFormat:@"%@, unmatched expectations = %@, unexpected values = %@, all expectations = %@, all values = %@", errorMessage, remainingExpectations, extraValues, expectations, values];
        NSError *error = [NSError errorWithDomain:@"com.livereload.LiveReload.tests" code:1 userInfo:@{NSLocalizedDescriptionKey: description}];
        if (outError)
            *outError = error;
        return NO;
    }
}
