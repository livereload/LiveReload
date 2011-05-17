
#import "LiveReloadAppDelegate.h"
#import "Workspace.h"
#import "StatusItemController.h"
#import "MainWindowController.h"
#import "CommunicationController.h"


@interface LiveReloadAppDelegate ()
@end


@implementation LiveReloadAppDelegate

@synthesize statusItemController=_statusItemController;
@synthesize mainWindowController=_mainWindowController;

// just to make XDry happy; won't ever be deallocated
- (void)dealloc {
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self.statusItemController showStatusBarIcon];
    [[CommunicationController sharedCommunicationController] startServer];
    [Workspace sharedWorkspace].monitoringEnabled = YES;
}

- (void)applicationDidResignActive:(NSNotification *)notification {
    [self.mainWindowController hideOnAppDeactivation];
}

@end
