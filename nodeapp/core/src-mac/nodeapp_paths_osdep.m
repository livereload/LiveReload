
#include "nodeapp_private.h"

void nodeapp_compute_paths_osdep() {
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];

    nodeapp_bundled_resources_dir = nsstrdup(resourcePath);

    NSString *libraryFolder = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"" NODEAPP_APPDATA_FOLDER];
    nodeapp_appdata_dir = nsstrdup(libraryFolder);

    NSString *logFolder = [libraryFolder stringByAppendingPathComponent:@"" NODEAPP_LOG_SUBFOLDER];
    nodeapp_log_dir = nsstrdup(logFolder);
    [[NSFileManager defaultManager] createDirectoryAtPath:logFolder withIntermediateDirectories:YES attributes:nil error:NULL];

    nodeapp_log_file = nsstrdup([logFolder stringByAppendingPathComponent:@"" NODEAPP_LOG_FILE]);
}
