
#import "GemVersion.h"
#import "GemVersionSpace.h"


@interface GemVersion ()

@property(nonatomic, readonly) NSArray *segments;

@end


@implementation GemVersion {
    NSString *_string;
}

// synthesize explicitly because the properties are initially declared in the superclass
@synthesize major=_major;
@synthesize minor=_minor;

- (id)initWithString:(NSString *)string segments:(NSArray *)segments error:(NSError *)error {
    self = [super initWithVersionSpace:[GemVersionSpace gemVersionSpace] error:error];
    if (self) {
        _string = string;
        _major = (segments.count >= 1 && [segments[0] isKindOfClass:NSNumber.class] ? [segments[0] integerValue] : 0);
        _minor = (segments.count >= 2 && [segments[1] isKindOfClass:NSNumber.class] ? [segments[1] integerValue] : 0);
        _segments = segments;
        _canonicalString = [segments componentsJoinedByString:@"."];
    }
    return self;
}

+ (instancetype)gemVersionWithString:(NSString *)string {
    static NSRegularExpression *overallPattern = nil, *componentPattern = nil, *digitsPattern = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        overallPattern = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+(\\.[0-9a-zA-Z]+)*$" options:0 error:NULL];
        componentPattern = [NSRegularExpression regularExpressionWithPattern:@"[0-9]+|[a-z]+" options:NSRegularExpressionCaseInsensitive error:NULL];
        digitsPattern = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+$" options:NSRegularExpressionCaseInsensitive error:NULL];
    });

    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (NSNotFound == [overallPattern rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)].location) {
        return [[self alloc] initWithString:string segments:@[] error:[NSError errorWithDomain:LRVersionErrorDomain code:LRVersionErrorCodeInvalidVersionNumber userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid gem version: '%@'", string]}]];
    };

    NSMutableArray *segments = [NSMutableArray new];
    [componentPattern enumerateMatchesInString:string options:0 range:NSMakeRange(0, string.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSString *match = [string substringWithRange:result.range];
        if (NSNotFound == [digitsPattern rangeOfFirstMatchInString:match options:0 range:NSMakeRange(0, match.length)].location) {
            [segments addObject:match];
        } else {
            [segments addObject:[NSNumber numberWithInteger:[match integerValue]]];
        }
    }];

    return [[self alloc] initWithString:string segments:segments error:nil];
}

+ (instancetype)gemVersionWithSegments:(NSArray *)segments {
    return [[self alloc] initWithString:[segments componentsJoinedByString:@"."] segments:segments error:nil];
}

- (NSString *)description {
    return _string;
}

- (NSComparisonResult)compare:(GemVersion *)rhs {
	if (!self.valid || !rhs.valid) {
        if (self.valid && !rhs.valid)
            return NSOrderedDescending;
        if (!self.valid && rhs.valid)
            return NSOrderedAscending;
        return NSOrderedSame;
	}

    NSArray *leftSegments = self.segments;
    NSArray *rightSegments = rhs.segments;

    NSInteger leftCount = leftSegments.count;
    NSInteger rightCount = rightSegments.count;
    NSInteger maxCount = MAX(leftCount, rightCount);

    for (NSInteger i = 0; i < maxCount; ++i) {
        id left = (i < leftCount ? leftSegments[i] : @(0));
        id right = (i < rightCount ? rightSegments[i] : @(0));

        if (![left isEqual:right]) {
            BOOL leftIsNumber = [left isKindOfClass:NSNumber.class];
            BOOL rightIsNumber = [right isKindOfClass:NSNumber.class];

            if (!leftIsNumber && rightIsNumber)
                return NSOrderedAscending;
            if (leftIsNumber && !rightIsNumber)
                return NSOrderedDescending;

            return [left compare:right];
        }
    }

    return NSOrderedSame;
}

@end
