
#import "GlitterDemoAppDelegate.h"
#import "Glitter.h"

extern Glitter *sharedGlitter;

@implementation GlitterDemoAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.window.title = [NSString stringWithFormat:@"GlitterDemo %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];

    [sharedGlitter checkForUpdatesWithOptions:GlitterCheckOptionUserInitiated];
}

@end
