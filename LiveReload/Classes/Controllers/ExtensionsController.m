
#import "ExtensionsController.h"


static ExtensionsController *sharedExtensionsController;


@implementation ExtensionsController

+ (ExtensionsController *)sharedExtensionsController {
    if (sharedExtensionsController == nil) {
        sharedExtensionsController = [[ExtensionsController alloc] init];
    }
    return sharedExtensionsController;
}

- (BOOL)isSafariExtensionInstalled {
    return NO;
}

- (IBAction)installSafariExtension:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LiveReload.safariextz" ofType:nil];
    NSAssert(path != nil, @"Cannot find LiveReload.safariextz");
    [[NSWorkspace sharedWorkspace] openFile:path];
}

@end
