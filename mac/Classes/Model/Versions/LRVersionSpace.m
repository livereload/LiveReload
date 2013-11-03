
#import "LRVersionSpace.h"
#import "LRVersion.h"
#import "LRVersionRange.h"
#import "LRVersionSet.h"


@implementation LRVersionSpace

- (LRVersion *)versionWithString:(NSString *)string {
    return nil;
}

- (LRVersionSet *)versionSetWithString:(NSString *)string {
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (string.length == 0 || [string isEqualToString:@"*"])
        return [LRVersionSet allVersionsSet];

    NSScanner *scanner = [NSScanner scannerWithString:string];

    LRVersion * __autoreleasing starting = nil;
    LRVersion * __autoreleasing ending = nil;
    BOOL startIncluded = YES, endIncluded = YES;
    BOOL rangeFound = NO;
    LRVersionRange *result = nil;

    if ([self _scanOperator:@"=" into:&starting using:scanner]) {
        result = [LRVersionRange versionRangeWithVersion:starting];
        goto check_end;
    }

    if ([self _scanOperator:@">=" into:&starting using:scanner]) {
        rangeFound = YES;
        startIncluded = YES;
    } else if ([self _scanOperator:@">" into:&starting using:scanner]) {
        rangeFound = YES;
        startIncluded = NO;
    }

    if ([self _scanOperator:@"<=" into:&ending using:scanner]) {
        rangeFound = YES;
        endIncluded = YES;
    } else if ([self _scanOperator:@"<" into:&ending using:scanner]) {
        rangeFound = YES;
        endIncluded = NO;
    }

    if (rangeFound) {
        result = [[LRVersionRange alloc] initWithStartingVersion:starting startIncluded:startIncluded endingVersion:ending endIncluded:endIncluded];
        goto check_end;
    }

    if ([self _scanOperator:@"" into:&starting using:scanner]) {
        result = [LRVersionRange versionRangeWithVersion:starting];
        goto check_end;
    }

    return [LRVersionSet emptyVersionSetWithError:[NSError errorWithDomain:LRVersionErrorDomain code:LRVersionErrorCodeInvalidRangeSpec userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid range spec: '%@'", string]}]];

check_end:
    if (![scanner isAtEnd]) {
        return [LRVersionSet emptyVersionSetWithError:[NSError errorWithDomain:LRVersionErrorDomain code:LRVersionErrorCodeInvalidRangeSpec userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Range spec '%@' has extra unparsable data '%@'", string, [string substringFromIndex:scanner.scanLocation]]}]];
    }

    return [LRVersionSet versionSetWithRange:result];
}

- (BOOL)_scanOperator:(NSString *)operator into:(LRVersion **)version using:(NSScanner *)scanner {
    NSCharacterSet *boundary = [NSCharacterSet characterSetWithCharactersInString:@"<>=~"];

    if (operator.length > 0 && ![scanner scanString:operator intoString:NULL])
        return NO;

    NSString * __autoreleasing s;
    if (![scanner scanUpToCharactersFromSet:boundary intoString:&s])
        return NO;

    *version = [self versionWithString:s];
    return YES;
}

@end
