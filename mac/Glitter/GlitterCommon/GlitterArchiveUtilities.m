
#import "GlitterArchiveUtilities.h"

void GlitterUnzip(NSURL *zipFile, NSURL *destinationFolder, void (^callback)(NSError *error)) {
    // using ditto because that's what Sparkle uses -- I would use unzip, but I imagine there's some problem with that
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/ditto";
    task.arguments = @[@"-x", @"-k", zipFile.path, destinationFolder.path];
    task.terminationHandler = ^(NSTask *task) {
        if (task.terminationStatus == 0) {
            callback(nil);
        } else {
            callback([NSError errorWithDomain:@"GlitterUnzip" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"ditto exit code %d", (int)task.terminationStatus]}]);
        }
    };
    [task launch];
}
