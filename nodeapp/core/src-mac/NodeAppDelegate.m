
#import "NodeAppDelegate.h"

#include "nodeapp.h"


@implementation NodeAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    nodeapp_init();
}

@end
