#import <Foundation/Foundation.h>


typedef void (^ATAnalyticsPropertiesBlock)(NSMutableDictionary *parameters);
@class ATAnalyticsPeriod;


@interface Analytics : NSObject

+ (void)initializeAnalytics;
+ (void)addPeriod:(ATAnalyticsPeriod *)period;

+ (void)addFlagNamed:(NSString *)name;
+ (void)addCounterNamed:(NSString *)name;
+ (void)addCountingSetNamed:(NSString *)name;
+ (void)addPropertiesBlock:(ATAnalyticsPropertiesBlock)valueBlock;

+ (void)trackEventNamed:(NSString *)name parameters:(NSDictionary *)parameters;

+ (void)setFlagNamed:(NSString *)name;
+ (void)incrementCounterNamed:(NSString *)name;
+ (void)includeValue:(NSString *)value intoCountingSetNamed:(NSString *)name;

@end


@interface ATAnalyticsPeriod : NSObject

- (instancetype)initWithIdentifier:(NSString *)identifier calendarUnits:(NSCalendarUnit)calendarUnits;

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSCalendarUnit calendarUnits;

- (void)setFlagNamed:(NSString *)name;
- (void)incrementCounterNamed:(NSString *)name;
- (void)includeValue:(NSString *)value intoCountingSetNamed:(NSString *)name;

@end
