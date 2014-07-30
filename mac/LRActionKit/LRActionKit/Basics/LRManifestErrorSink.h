@import Foundation;

@protocol LRManifestErrorSink <NSObject>

- (void)addErrorMessage:(NSString *)message;

@end
