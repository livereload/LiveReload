@import Foundation;
#import "LRManifestErrorSink.h"


@interface LRManifestBasedObject : NSObject <LRManifestErrorSink>

- (instancetype)initWithManifest:(NSDictionary *)manifest errorSink:(id<LRManifestErrorSink>)errorSink;

@property(nonatomic, readonly, weak) id<LRManifestErrorSink> errorSink;
@property(nonatomic, readonly, copy) NSDictionary *manifest;

@property(nonatomic, readonly) BOOL valid;
@property(nonatomic, readonly, copy) NSArray *errors;

- (void)addErrorMessage:(NSString *)message;

@end
