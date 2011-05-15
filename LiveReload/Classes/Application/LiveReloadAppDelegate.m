
#import "LiveReloadAppDelegate.h"
#import "Workspace.h"
#import "StatusItemController.h"


@interface LiveReloadAppDelegate ()

@property(nonatomic, retain) StatusItemController *statusItemController;

@end


@implementation LiveReloadAppDelegate

@synthesize window;
@synthesize statusItemController=_statusItemController;

// just to make XDry happy; won't ever be deallocated
- (void)dealloc {
    [window release], window = nil;
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItemController = [[[StatusItemController alloc] init] autorelease];
    [Workspace sharedWorkspace].monitoringEnabled = YES;
}

@end
