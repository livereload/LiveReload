#import <Foundation/Foundation.h>

@interface Analytics : NSObject

+ (void)initializeAnalytics;

+ (void)trackEventNamed:(NSString *)name parameters:(NSDictionary *)parameters;

@end
