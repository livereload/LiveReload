
#import "LiveReloadAppDelegate.h"
#import "Workspace.h"


@implementation LiveReloadAppDelegate

@synthesize window;

// just to make XDry happy; won't ever be deallocated
- (void)dealloc {
    [window release], window = nil;
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [Workspace sharedWorkspace].monitoringEnabled = YES;
}

@end
