
#import "LiveReloadAppDelegate.h"
#import "Workspace.h"
#import "StatusItemController.h"


@interface LiveReloadAppDelegate ()
@end


@implementation LiveReloadAppDelegate

@synthesize statusItemController=_statusItemController;

// just to make XDry happy; won't ever be deallocated
- (void)dealloc {
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self.statusItemController showStatusBarIcon];
    [Workspace sharedWorkspace].monitoringEnabled = YES;
}

@end
