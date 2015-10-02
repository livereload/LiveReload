
#import "LRTRTestAnythingProtocolParser.h"
#import "LRTRGlobals.h"


static NSRegularExpression *kTestCountRegexp;
static NSRegularExpression *kSkipDirectiveRegexp;
static NSRegularExpression *kTodoDirectiveRegexp;
static NSRegularExpression *kBailOutRegexp;
static NSCharacterSet *kHashCharacterSet;
static NSCharacterSet *kEmptyCharacterSet;
static NSCharacterSet *kUselessDescriptionCharacterSet;

static void initialize_re() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kTestCountRegexp = [NSRegularExpression regularExpressionWithPattern:@"^(\\d+)..(\\d+)" options:0 error:NULL];
        kSkipDirectiveRegexp = [NSRegularExpression regularExpressionWithPattern:@"^SKIP\\S*(?:\\s+(\\S.*))?$" options:NSRegularExpressionCaseInsensitive error:NULL];
        kTodoDirectiveRegexp = [NSRegularExpression regularExpressionWithPattern:@"^TODO(?:\\s+(\\S.*))?$" options:NSRegularExpressionCaseInsensitive error:NULL];
        kBailOutRegexp = [NSRegularExpression regularExpressionWithPattern:@"^Bail out!(?:\\s+(\\S.*))?$" options:NSRegularExpressionCaseInsensitive error:NULL];
        kHashCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"#"];
        kEmptyCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@""];
        kUselessDescriptionCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"-"];
    });
}


@interface LRTRTestAnythingProtocolParser ()

@end


@implementation LRTRTestAnythingProtocolParser {
    NSInteger _lastTestNumber;
    NSInteger _testCount;
}

+ (void)initialize {
    initialize_re();
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _testCount = -1;
    }
    return self;
}

- (void)processLine:(NSString *)line {
    NSTextCheckingResult *match;

    NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    if (!!(match = [kTestCountRegexp firstMatchInString:trimmed options:0 range:NSMakeRange(0, trimmed.length)])) {
        _testCount = [[trimmed substringWithRange:[match rangeAtIndex:2]] integerValue];
    } else if ([trimmed hasPrefix:@"ok"]) {
        [self processTestResultLine:[trimmed substringFromIndex:[@"ok" length]] ok:YES];
    } else if ([trimmed hasPrefix:@"not ok"]) {
        [self processTestResultLine:[trimmed substringFromIndex:[@"not ok" length]] ok:NO];
    } else if ([trimmed hasPrefix:@"#"]) {
        // ignore
    } else if ([trimmed hasPrefix:@"TAP version "]) {
        // TODO
    } else if (!!(match = [kBailOutRegexp firstMatchInString:trimmed options:0 range:NSMakeRange(0, trimmed.length)])) {
        //
    } else {
        [self.delegate appendExtraOutput:line];
    }
}

- (void)finish {
    if (_testCount >= 0 && _lastTestNumber < _testCount) {
        for (NSInteger testNumber = _lastTestNumber + 1; testNumber <= _testCount; ++testNumber) {
            [self.delegate finishedTestNamed:[NSString stringWithFormat:@"Missing test %d", (int)testNumber] withStatus:LRTRTestStatusFailed];
        }
    }
}

- (void)processTestResultLine:(NSString *)line ok:(BOOL)ok {
    NSScanner *scanner = [NSScanner scannerWithString:line];

    NSInteger testNumber;
    NSString *description = @"";
    NSString *directive = @"";
    BOOL skipped = NO, todo = NO;

    if (![scanner scanInteger:&testNumber]) {
        testNumber = _lastTestNumber + 1;
    }

    [scanner scanUpToCharactersFromSet:kHashCharacterSet intoString:&description];
    [NSCharacterSet characterSetWithCharactersInString:@""];

    if ([scanner scanCharactersFromSet:kHashCharacterSet intoString:NULL]) {
        [scanner scanCharactersFromSet:kEmptyCharacterSet intoString:&directive];

        NSTextCheckingResult *match;
        if (!!(match = [kSkipDirectiveRegexp firstMatchInString:directive options:0 range:NSMakeRange(0, directive.length)])) {
            skipped = YES;
        } else if (!!(match = [kTodoDirectiveRegexp firstMatchInString:directive options:0 range:NSMakeRange(0, directive.length)])) {
            todo = YES;
        }
    }

    _lastTestNumber = testNumber;

    LRTRTestStatus status;
    if (skipped || todo) {
        status = LRTRTestStatusSkipped;
    } else if (ok) {
        status = LRTRTestStatusSucceeded;
    } else {
        status = LRTRTestStatusFailed;
    }

    description = [description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    description = [description stringByTrimmingCharactersInSet:kUselessDescriptionCharacterSet];
    if (description.length == 0) {
        description = [NSString stringWithFormat:@"Test %d", (int)testNumber];
    }

    [self.delegate finishedTestNamed:description withStatus:status];
}


@end
