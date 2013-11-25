
#import <Foundation/Foundation.h>

@protocol LRManifestErrorSink <NSObject>

- (void)addErrorMessage:(NSString *)message;

@end
