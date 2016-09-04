#import "Analytics.h"

#define PADDLE_AVAILABLE 1
#define PARSE_AVAILABLE 0
#define FABRIC_AVAILABLE 0


#if PADDLE_AVAILABLE
#import <Paddle/Paddle.h>
#import <Paddle/PaddleAnalyticsKit.h>
#endif
#if PARSE_AVAILABLE
#import <ParseOSX/Parse.h>
#endif
#import "LicenseManager.h"
#import "MASReceipt.h"




typedef struct {
    long lower;
    long upper;
} ATReducedPrecisionRange;

static ATReducedPrecisionRange ATReducedPrecisionRangeFromValue(long value) {
    if (value < 0) {
        ATReducedPrecisionRange range = ATReducedPrecisionRangeFromValue(-value);
        return (ATReducedPrecisionRange) {-range.upper, -range.lower};
    } else if (value == 0) {
        return (ATReducedPrecisionRange) {0, 0};
    } else if (value == 1) {
        return (ATReducedPrecisionRange) {1, 1};
    } else if (value <= 9) {
        return (ATReducedPrecisionRange) {2, 9};
    } else if (value <= 29) {
        return (ATReducedPrecisionRange) {10, 29};
    } else if (value <= 99) {
        return (ATReducedPrecisionRange) {30, 99};
    } else {
        double l = log10(value);
        double k = floor(l);
        long a = (long) (pow(10, k));
        long b = (long) (pow(10, k+1)) - 1;
        return (ATReducedPrecisionRange) {a, b};
    }
}

static NSString *ATReducedPrecisionRangeStringFromValue(long value) {
    ATReducedPrecisionRange range = ATReducedPrecisionRangeFromValue(value);
    if (range.lower == range.upper) {
        return [NSString stringWithFormat:@"%ld", value];
    } else {
        return [NSString stringWithFormat:@"%ld..%ld", range.lower, range.upper];
    }
}


static NSMutableArray *_propertiesBlocks;
static NSMutableArray *_counterNames;
static NSMutableArray *_flagNames;
static NSMutableArray *_countingSetNames;
static NSMutableArray *_periods;


@implementation Analytics

static BOOL _logOnly;

+ (void)initializeAnalytics {
#if PADDLE_AVAILABLE
    Paddle *paddle = [Paddle sharedInstance];
    [paddle setProductId:@"497612"];
    [paddle setVendorId:@"128"];
    [paddle setApiKey:@"c125288cc41c57b7e47ba5a63797328b"];
#endif
    
#if PARSE_AVAILABLE
    [Parse setApplicationId:@"gUXVcl38ni3258sQfWdErdNuxF9ZC1yEY1pTIpPv" clientKey:@"4r10RsuIL34gtSdfebXTWOJPrIbSL3kC7xn41sIf"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:nil];
    [PFAnalytics trackEvent:@"read" dimensions:dimensions];
#endif
    
    _logOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.livereload.debug.analytics.logEvents"];
}

+ (void)trackEventNamed:(NSString *)name parameters:(NSDictionary *)parameters {
    NSMutableDictionary *params = [(parameters ?: @[]) mutableCopy];
    params[@"os"] = @"mac";
#ifdef APPSTORE
    params[@"licensing"] = @"MAS";
#else
    if (MASReceiptIsAuthenticated()) {
        params[@"licensing"] = @"MAS-based";
    } else if (LicenseManagerIsTrialMode()) {
        params[@"licensing"] = @"trial";
    } else {
        params[@"licensing"] = @"purchased";
    }
#endif

    // reduce precision automatically
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            params[key] = ATReducedPrecisionRangeStringFromValue([obj longValue]);
        }
    }];

    if (_logOnly) {
        NSMutableArray *result = [NSMutableArray new];
        [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [result addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
        }];
        [result sortedArrayUsingSelector:@selector(compare:)];
        NSLog(@"LiveReload Analytics: %@ (%@)", name, [result componentsJoinedByString:@" "]);
    } else {
#if PADDLE_AVAILABLE
        [PaddleAnalyticsKit track:name properties:params];
#endif
#if PARSE_AVAILABLE
        [PFAnalytics trackEvent:name dimensions:params];
#endif
    }
}

+ (void)addPropertiesBlock:(ATAnalyticsPropertiesBlock)valueBlock {
    if (_propertiesBlocks == nil) {
        _propertiesBlocks = [NSMutableArray new];
    }
    [_propertiesBlocks addObject:[valueBlock copy]];
}

+ (void)addFlagNamed:(NSString *)name {
    if (_flagNames == nil) {
        _flagNames = [NSMutableArray new];
    }
    [_flagNames addObject:name];
}

+ (void)addCounterNamed:(NSString *)name {
    if (_counterNames == nil) {
        _counterNames = [NSMutableArray new];
    }
    [_counterNames addObject:name];
}

+ (void)addCountingSetNamed:(NSString *)name {
    if (_countingSetNames == nil) {
        _countingSetNames = [NSMutableArray new];
    }
    [_countingSetNames addObject:name];
}

+ (void)addPeriod:(ATAnalyticsPeriod *)period {
    if (_periods == nil) {
        _periods = [NSMutableArray new];
    }
    [_periods addObject:period];
}

+ (void)setFlagNamed:(NSString *)name {
    for (ATAnalyticsPeriod *period in _periods) {
        [period setFlagNamed:name];
    }
}

+ (void)incrementCounterNamed:(NSString *)name {
    for (ATAnalyticsPeriod *period in _periods) {
        [period incrementCounterNamed:name];
    }
}

+ (void)includeValue:(NSString *)value intoCountingSetNamed:(NSString *)name {
    for (ATAnalyticsPeriod *period in _periods) {
        [period includeValue:value intoCountingSetNamed:name];
    }
}

@end


@implementation ATAnalyticsPeriod

- (instancetype)initWithIdentifier:(NSString *)identifier calendarUnits:(NSCalendarUnit)calendarUnits {
    self = [super init];
    if (self) {
        _identifier = identifier;
        _calendarUnits = calendarUnits;
    }
    return self;
}

- (void)setFlagNamed:(NSString *)name {
    if (![_flagNames containsObject:name]) {
        [NSException raise:NSInvalidArgumentException format:@"Flags must first be added via addFlagNamed:"];
    }
    
    [self checkFirstUsePerPeriod];
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString *key = [self _keyForMetricNamed:name];
    [def setBool:YES forKey:key];
}

- (void)incrementCounterNamed:(NSString *)name {
    if (![_counterNames containsObject:name]) {
        [NSException raise:NSInvalidArgumentException format:@"Counters must first be added via addCounterNamed:"];
    }
    
    [self checkFirstUsePerPeriod];
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString *key = [self _keyForMetricNamed:name];
    NSInteger value = [def integerForKey:key];
    value += 1;
    [def setInteger:value forKey:key];
}

- (void)includeValue:(NSString *)value intoCountingSetNamed:(NSString *)name {
    if (![_countingSetNames containsObject:name]) {
        [NSException raise:NSInvalidArgumentException format:@"Counting sets must first be added via addCountingSetNamed:"];
    }
    
    [self checkFirstUsePerPeriod];
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString *key = [self _keyForMetricNamed:name];
    NSArray *members = [def arrayForKey:key] ?: @[];
    if (![members containsObject:value]) {
        members = [members arrayByAddingObject:value];
    }
    [def setObject:members forKey:key];
}

- (NSString *)_keyForMetricNamed:(NSString *)name {
    return [NSString stringWithFormat:@"analytics.%@.%@", _identifier, name];
}

- (void)checkFirstUsePerPeriod {
    static NSCalendar *calendar;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    });
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSString *key = [self _keyForMetricNamed:@"timestamp"];
    NSTimeInterval lastUseUnixTime = [def doubleForKey:key];
    
    // will give a date around 1970 when lastUse is zero, which is fine for us
    NSDate *lastUse = [NSDate dateWithTimeIntervalSince1970:lastUseUnixTime];
    NSDateComponents *lastUseComponents = [calendar components:_calendarUnits fromDate:lastUse];
    
    NSDate *now = [NSDate date];
    NSDateComponents *nowComponents = [calendar components:_calendarUnits fromDate:now];
    
    if (![lastUseComponents isEqual:nowComponents]) {
        [def setDouble:now.timeIntervalSince1970 forKey:key];
        [self sendData];
        [self resetData];
    }
}

- (void)sendData {
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    
    for (NSString *name in _flagNames) {
        NSString *key = [self _keyForMetricNamed:name];
        BOOL value = [def boolForKey:key];
        parameters[name] = (value ? @"YES" : @"NO");
    }

    for (NSString *name in _counterNames) {
        NSString *key = [self _keyForMetricNamed:name];
        NSInteger value = [def integerForKey:key];
        parameters[name] = @(value);
    }
    
    for (NSString *name in _countingSetNames) {
        NSString *key = [self _keyForMetricNamed:name];
        NSArray *members = [def arrayForKey:key] ?: @[];
        parameters[name] = @(members.count);
    }

    for (ATAnalyticsPropertiesBlock block in _propertiesBlocks) {
        block(parameters);
    }

    [Analytics trackEventNamed:_identifier parameters:parameters];
}

- (void)resetData {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    for (NSString *counterName in _counterNames) {
        NSString *key = [self _keyForMetricNamed:counterName];
        [def removeObjectForKey:key];
    }
}

@end
