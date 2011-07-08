
#import "LiveReloadAppDelegate.h"
#import "Workspace.h"
#import "StatusItemController.h"
#import "MainWindowController.h"
#import "CommunicationController.h"
#import "LoginItemController.h"
#import "PluginManager.h"


@interface LiveReloadAppDelegate ()

- (void)pingServer;

@end


@implementation LiveReloadAppDelegate

@synthesize statusItemController=_statusItemController;
@synthesize mainWindowController=_mainWindowController;

// just to make XDry happy; won't ever be deallocated
- (void)dealloc {
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSDate *now = [NSDate date];
    NSDateComponents *cutoff = [[[NSDateComponents alloc] init] autorelease];
    [cutoff setYear:2011];
    [cutoff setMonth:9];
    [cutoff setDay:1];
    if ([now compare:[[NSCalendar currentCalendar] dateFromComponents:cutoff]] == NSOrderedDescending) {
        // stop auto-login and show a message
        NSInteger ans = [[NSAlert alertWithMessageText:@"LiveReload 2 beta has expired"
                                         defaultButton:@"Visit our site"
                                       alternateButton:@"Quit LiveReload"
                                           otherButton:nil
                             informativeTextWithFormat:@"Sorry, this beta version of LiveReload has expired and cannot be launched.\n\nPlease visit http://livereload.mockko.com/ to get an updated version."] runModal];
        if (ans == NSAlertDefaultReturn) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://livereload.mockko.com/"]];
        } else {
            [LoginItemController sharedController].loginItemEnabled = NO;
        }
        [NSApp terminate:self];
    }

    [[PluginManager sharedPluginManager] reloadPlugins];
    [self.mainWindowController startUp];

    [self pingServer];
    [NSTimer scheduledTimerWithTimeInterval:60*60*24 target:self selector:@selector(pingServer) userInfo:nil repeats:YES];

    [self.statusItemController showStatusBarIcon];
    [[CommunicationController sharedCommunicationController] startServer];
    [self.mainWindowController performSelector:@selector(considerShowingOnAppStartup) withObject:nil afterDelay:0.15];
}

- (void)applicationDidResignActive:(NSNotification *)notification {
    [self.mainWindowController hideOnAppDeactivation];
}

- (void)pingServer {
    [self performSelectorInBackground:@selector(pingServerInBackground) withObject:nil];
}

- (void)pingServerInBackground {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *internalVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://livereload.com/ping.php?v=%@&iv=%@", [version stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [internalVersion stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
    [pool drain];
}

@end
