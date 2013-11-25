
#import <Foundation/Foundation.h>
#import "LRManifestErrorSink.h"


@interface LRChildErrorSink : NSObject <LRManifestErrorSink>

+ (instancetype)childErrorSinkWithParentSink:(id<LRManifestErrorSink>)parentSink context:(NSString *)context uncleSink:(id<LRManifestErrorSink>)uncleSink;

@end
