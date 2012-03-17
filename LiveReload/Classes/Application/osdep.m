
#include "osdep.h"
#include "autorelease.h"
#include "common.h"

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

void invoke_on_main_thread(INVOKE_LATER_FUNC func, void *context) {
    dispatch_async(dispatch_get_main_queue(), ^{
        func(context);
    });
}

//----------------------------------

const char *os_bundled_resources_path;
const char *os_bundled_backend_path;
const char *os_bundled_node_path;
const char *os_preferences_path;
const char *os_log_path;

static void os_compute_paths() {
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];

    os_bundled_resources_path = strdup([resourcePath UTF8String]);
    os_bundled_node_path = strdup([[resourcePath stringByAppendingPathComponent:@"node"] UTF8String]);
    os_bundled_backend_path = strdup([[resourcePath stringByAppendingPathComponent:@"backend"] UTF8String]);

    NSString *libraryFolder = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"LiveReload"];

    NSString *logFolder = [libraryFolder stringByAppendingPathComponent:@"Logs"];
    NSString *dataFolder = [libraryFolder stringByAppendingPathComponent:@"Data"];

    os_log_path = strdup([logFolder UTF8String]);
    os_preferences_path = strdup([dataFolder UTF8String]);

    [[NSFileManager defaultManager] createDirectoryAtPath:logFolder withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:dataFolder withIntermediateDirectories:YES attributes:nil error:NULL];
}

void os_init() {
    os_compute_paths();
}
