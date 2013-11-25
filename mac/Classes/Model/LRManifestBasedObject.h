
#import <Foundation/Foundation.h>
#import "LRManifestErrorSink.h"


@interface LRManifestBasedObject : NSObject <LRManifestErrorSink>

- (instancetype)initWithManifest:(NSDictionary *)manifest errorSink:(id<LRManifestErrorSink>)errorSink;

@property(nonatomic, readonly) __weak id<LRManifestErrorSink> errorSink;
@property(nonatomic, readonly) NSDictionary *manifest;

@property(nonatomic, readonly) BOOL valid;
@property(nonatomic, readonly, copy) NSArray *errors;

- (void)addErrorMessage:(NSString *)message;

@end
