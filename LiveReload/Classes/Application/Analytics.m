#import "Analytics.h"
#import <Paddle/Paddle.h>
#import <Paddle/PaddleAnalyticsKit.h>
#import <ParseOSX/Parse.h>

@implementation Analytics

+ (void)initializeAnalytics {
    Paddle *paddle = [Paddle sharedInstance];
    [paddle setProductId:@"497612"];
    [paddle setVendorId:@"128"];
    [paddle setApiKey:@"c125288cc41c57b7e47ba5a63797328b"];
    
    [Parse setApplicationId:@"gUXVcl38ni3258sQfWdErdNuxF9ZC1yEY1pTIpPv" clientKey:@"4r10RsuIL34gtSdfebXTWOJPrIbSL3kC7xn41sIf"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:nil];
    // [PFAnalytics trackEvent:@"read" dimensions:dimensions];
}

+ (void)trackEventNamed:(NSString *)name parameters:(NSDictionary *)parameters {
    [PFAnalytics trackEvent:name dimensions:parameters];
    [PaddleAnalyticsKit track:name properties:parameters];
}

@end
