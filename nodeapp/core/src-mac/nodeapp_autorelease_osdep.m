
#include "nodeapp_private.h"

#import <Foundation/Foundation.h>


@interface AutoReleaseMarker : NSObject
@end

@implementation AutoReleaseMarker

- (void)dealloc {
    nodeapp_autorelease_cleanup();
    [super dealloc];
}

@end

void nodeapp_autorelease_pool_activate() {
    [[[AutoReleaseMarker alloc] init] autorelease];
}
