
#import "LROption.h"


@protocol LRManifestErrorSink;


@interface LROption (Factory)

+ (LROption *)optionWithSpec:(NSDictionary *)spec action:(Rule *)action errorSink:(id<LRManifestErrorSink>)errorSink;

@end
