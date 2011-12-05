
#include "common.h"
#include "osdep.h"
#include "autorelease.h"
#include <string.h>
#include "stringutil.h"

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

const char *os_bundled_resources_path;
const char *os_bundled_node_path;

void os_init() {
    os_bundled_resources_path = strdup([[[NSBundle mainBundle] resourcePath] UTF8String]);
    os_bundled_node_path = str_printf("%s/node", os_bundled_resources_path);
}

void invoke_on_main_thread(INVOKE_LATER_FUNC func, void *context) {
    dispatch_async_f(dispatch_get_main_queue(), context, func);
}
