//
//  PaddleAnalyticsKit.h
//  PaddleAnalytics
//
//  Created by Louis Harwood on 26/08/2014.
//  Copyright (c) 2014 Paddle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum appStores
{
    PAKPaddle,
    PAKiOS,
    PAKMacAppStore,
    PAKOther
} Store;

@interface PaddleAnalyticsKit : NSObject

+ (void)startTracking;
+ (void)track:(NSString *)action properties:(NSDictionary *)properties;
+ (void)identify:(NSString *)identifier;
+ (void)payment:(NSNumber *)amount currency:(NSString *)currency product:(NSString *)product store:(Store)store;

+ (void)disableTracking;

+ (void)enableOptin;
+ (BOOL)isOptedIn;
+ (void)presentOptinDialog;

@end
