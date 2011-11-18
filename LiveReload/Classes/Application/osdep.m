
#include "osdep.h"
#include "autorelease.h"

#import <Cocoa/Cocoa.h>


//----------------------------------

@interface AutoReleaseMarker : NSObject
@end

@implementation AutoReleaseMarker

- (void)dealloc {
    autorelease_cleanup();
    [super dealloc];
}

@end

void autorelease_pool_activate() {
    [[[AutoReleaseMarker alloc] init] autorelease];
}

//----------------------------------

void os_init() {
}

const char *os_bundled_resources_path() {
    return [[[NSBundle mainBundle] resourcePath] UTF8String];
}
