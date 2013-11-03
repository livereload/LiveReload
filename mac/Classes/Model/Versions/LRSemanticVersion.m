
#import "LRSemanticVersion.h"
#import "LRSemanticVersionSpace.h"


@implementation LRSemanticVersion {
    NSString *_description;
}

- (id)initWithMajor:(NSInteger)major minor:(NSInteger)minor patch:(NSInteger)patch prereleaseComponents:(NSArray *)prereleaseComponents build:(NSString *)build error:(NSError *)error {
    self = [super initWithVersionSpace:[LRSemanticVersionSpace semanticVersionSpace] error:error];
    if (self) {
        _major = major;
        _minor = minor;
        _patch = patch;

        _prereleaseComponents = [prereleaseComponents copy] ?: @[];

        _prerelease = [_prereleaseComponents componentsJoinedByString:@"."];
        _build = [_build copy] ?: @"";

        NSString *description = [NSString stringWithFormat:@"%d.%d.%d", (int)_major, (int)_minor, (int)_patch];
        if (_prerelease.length > 0)
            description = [NSString stringWithFormat:@"%@-%@", description, _prerelease];
        if (_build.length > 0)
            description = [NSString stringWithFormat:@"%@+%@", description, _build];
        _description = description;
    }
    return self;
}

+ (instancetype)semanticVersionWithString:(NSString *)string {
    LRVersionErrorCode errorCode = LRVersionErrorCodeNone;
    NSError *error = nil;
    NSInteger major = 0, minor = 0, patch = 0;
    NSMutableArray *prereleaseComponents = [NSMutableArray new];
    NSString *build = @"";

    NSScanner *scanner = [NSScanner scannerWithString:string];

    [scanner scanString:@"=" intoString:NULL];
    [scanner scanString:@"v" intoString:NULL];

    if (![scanner scanInteger:&major]) {
        errorCode = LRVersionErrorCodeInvalidVersionNumber;
        goto finish;
    }

    if ([scanner scanString:@"." intoString:NULL]) {
        if (![scanner scanInteger:&minor]) {
            errorCode = LRVersionErrorCodeInvalidVersionNumber;
            goto finish;
        }

        if ([scanner scanString:@"." intoString:NULL]) {
            if (![scanner scanInteger:&patch]) {
                errorCode = LRVersionErrorCodeInvalidVersionNumber;
                goto finish;
            }

            while ([scanner scanString:@"." intoString:NULL]) {
                NSInteger dummy;
                if (![scanner scanInteger:&dummy]) {
                    errorCode = LRVersionErrorCodeInvalidExtraVersionNumber;
                    goto finish;
                }
            }
        }
    }

    if ([scanner scanString:@"-" intoString:NULL]) {
        NSCharacterSet *boundary = [NSCharacterSet characterSetWithCharactersInString:@".+"];
        do {
            NSInteger intComponent = 0;
            NSString *stringComponent = nil;
            if ([scanner scanInteger:&intComponent]) {
                [prereleaseComponents addObject:@(intComponent)];
            } else if ([scanner scanUpToCharactersFromSet:boundary intoString:&stringComponent]) {
                [prereleaseComponents addObject:stringComponent];
            } else {
                errorCode = LRVersionErrorCodeInvalidPrereleaseComponent;
                goto finish;
            }
        } while ([scanner scanString:@"." intoString:NULL]);
    }

    if ([scanner scanString:@"+" intoString:NULL]) {
        build = [[string substringFromIndex:scanner.scanLocation] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }

finish:
    if (errorCode != LRVersionErrorCodeNone) {
        error = [NSError errorWithDomain:LRVersionErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid semver: '%@'", string]}];
    }
    return [[self alloc] initWithMajor:major minor:minor patch:patch prereleaseComponents:prereleaseComponents build:build error:error];
}

- (NSString *)description {
    return _description;
}

- (NSComparisonResult)compare:(LRSemanticVersion *)rhs {
	if (!self.valid || !rhs.valid) {
        if (self.valid && !rhs.valid)
            return NSOrderedDescending;
        if (!self.valid && rhs.valid)
            return NSOrderedAscending;
        return NSOrderedSame;
	}

    if (self.major != rhs.major)
        return [@(self.major) compare:@(rhs.major)];
    if (self.minor != rhs.minor)
        return [@(self.minor) compare:@(rhs.minor)];
    if (self.patch != rhs.patch)
        return [@(self.patch) compare:@(rhs.patch)];

    if (![self.prerelease isEqualToString:rhs.prerelease]) {
        if (self.prerelease.length > 0 && rhs.prerelease.length == 0)
            return NSOrderedAscending;
        if (self.prerelease.length == 0 && rhs.prerelease.length != 0)
            return NSOrderedDescending;
        return [self.prerelease compare:rhs.prerelease options:NSNumericSearch];
    }

    return NSOrderedSame;
}

@end
