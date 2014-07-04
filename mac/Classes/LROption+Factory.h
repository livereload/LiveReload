
#import "LROption.h"


@protocol LRManifestErrorSink;


@interface LROption (Factory)

+ (LROption *)optionWithSpec:(NSDictionary *)spec rule:(Rule *)rule errorSink:(id<LRManifestErrorSink>)errorSink;

@end
