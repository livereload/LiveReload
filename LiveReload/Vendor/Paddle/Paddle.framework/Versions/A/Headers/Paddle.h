//
//  Paddle.h
//  Paddle
//
//  Created by Louis Harwood on 08/01/2015.
//  Copyright (c) 2015 Paddle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Paddle : NSObject {
    BOOL hasTrackingStarted;
}

@property (assign) BOOL hasTrackingStarted;

+ (Paddle *)sharedInstance;
- (void)setApiKey:(NSString *)apiKey;
- (void)setVendorId:(NSString *)vendorId;
- (void)setProductId:(NSString *)productId;

@end
