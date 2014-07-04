
#import "LROption.h"


@protocol LRManifestErrorSink;


@interface LROption (Factory)

+ (LROption *)optionWithSpec:(NSDictionary *)spec action:(Action *)action errorSink:(id<LRManifestErrorSink>)errorSink;

@end
