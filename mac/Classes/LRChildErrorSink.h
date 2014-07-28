
#import <Foundation/Foundation.h>
@import LRActionKit;


@interface LRChildErrorSink : NSObject <LRManifestErrorSink>

+ (instancetype)childErrorSinkWithParentSink:(id<LRManifestErrorSink>)parentSink context:(NSString *)context uncleSink:(id<LRManifestErrorSink>)uncleSink;

@end
