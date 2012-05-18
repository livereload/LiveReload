
#include "osdep.h"
#include "autorelease.h"
#include "common.h"
#include "jansson.h"

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

void C_app__failed_to_start(json_t *arg) {
    const char *msg = json_string_value(json_object_get(arg, "message"));
    [[NSAlert alertWithMessageText:@"LiveReload failed to start" defaultButton:@"Quit" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%s", msg] runModal];
    [NSApp terminate:nil];
}

void os_emergency_shutdown_backend_crashed() {
    NSInteger result = [[NSAlert alertWithMessageText:@"LiveReload Crash" defaultButton:@"Troubleshooting Instructions" alternateButton:@"Just Quit" otherButton:nil informativeTextWithFormat:@"My backend has decided to be very naughty, so looks like I have to crash."] runModal];
    if (result == NSAlertDefaultReturn) {
        NSString *logFile = [[NSString stringWithUTF8String:os_log_path] stringByAppendingPathComponent:@"log.txt"];
        [[NSWorkspace sharedWorkspace] selectFile:logFile inFileViewerRootedAtPath:nil];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://help.livereload.com/kb/troubleshooting/livereload-has-crashed-on-a-mac"]];
    }
    [NSApp terminate:nil];
}

//----------------------------------

const char *os_bundled_resources_path;
const char *os_bundled_backend_path;
const char *os_bundled_node_path;
const char *os_preferences_path;
const char *os_log_path;
const char *os_log_file;

static void os_compute_paths() {
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];

    os_bundled_resources_path = strdup([resourcePath UTF8String]);
    os_bundled_node_path = strdup([[resourcePath stringByAppendingPathComponent:@"LiveReloadNodejs"] UTF8String]);
    os_bundled_backend_path = strdup([[resourcePath stringByAppendingPathComponent:@"backend"] UTF8String]);

    NSString *libraryFolder = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"LiveReload"];

    NSString *logFolder = [libraryFolder stringByAppendingPathComponent:@"Logs"];
    NSString *dataFolder = [libraryFolder stringByAppendingPathComponent:@"Data"];

    os_log_path = strdup([logFolder UTF8String]);
    os_log_file = strdup([[logFolder stringByAppendingPathComponent:@"log.txt"] UTF8String]);
    os_preferences_path = strdup([dataFolder UTF8String]);

    [[NSFileManager defaultManager] createDirectoryAtPath:logFolder withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:dataFolder withIntermediateDirectories:YES attributes:nil error:NULL];
}

static void os_init_logging() {
    int fd = open(os_log_file, O_WRONLY | O_CREAT | O_TRUNC, 0664);
    dup2(fd, 2);
    close(fd);
}

void os_init() {
    os_compute_paths();
    os_init_logging();
}
