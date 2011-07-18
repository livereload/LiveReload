
#import "LiveReloadAppDelegate.h"
#import "Workspace.h"
#import "StatusItemController.h"
#import "MainWindowController.h"
#import "PreferencesWindowController.h"
#import "CommunicationController.h"
#import "LoginItemController.h"
#import "PluginManager.h"

#import "NSWindowFlipper.h"


@interface LiveReloadAppDelegate ()

- (void)pingServer;
- (void)considerShowingWindowOnAppStartup;

@end


@implementation LiveReloadAppDelegate

@synthesize statusItemController=_statusItemController;
@synthesize mainWindowController=_mainWindowController;
@synthesize preferencesWindowController = _preferencesWindowController;

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

    _statusItemController = [[StatusItemController alloc] init];
    [self.statusItemController showStatusBarIcon];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        _mainWindowController = [[MainWindowController alloc] init];
        _preferencesWindowController = [[PreferencesWindowController alloc] init];

        [[CommunicationController sharedCommunicationController] startServer];

        [self considerShowingWindowOnAppStartup];

        [self pingServer];
        [NSTimer scheduledTimerWithTimeInterval:60*60*24 target:self selector:@selector(pingServer) userInfo:nil repeats:YES];
    });
}

- (void)applicationDidResignActive:(NSNotification *)notification {
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


#pragma mark -

- (void)positionWindow:(NSWindow *)window {
    NSRect frame = window.frame;
    NSPoint itemPos = self.statusItemController.statusItemPosition;
    frame.origin.x = itemPos.x - frame.size.width / 2;
    frame.origin.y = itemPos.y - frame.size.height;
    [window setFrame:frame display:YES];
}

- (BOOL)isMainWindowVisible {
    return [self.mainWindowController.window isVisible];
}

- (BOOL)isPreferencesWindowVisible {
    return [self.preferencesWindowController.window isVisible];
}

- (BOOL)isWindowVisible {
    return [self isMainWindowVisible] || [self isPreferencesWindowVisible];
}

- (IBAction)displayMainWindow:sender {
    [self positionWindow:self.mainWindowController.window];
    [self.mainWindowController willShow];
    if ([self isPreferencesWindowVisible]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:PreferencesDoneKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [self.preferencesWindowController.window flipToWindow:self.mainWindowController.window withDuration:0.5 shadowed:NO];
    } else {
        [NSApp activateIgnoringOtherApps:YES];
        [self.mainWindowController.window makeKeyAndOrderFront:nil];
    }
}

- (IBAction)displayPreferencesWindow:sender {
    [self positionWindow:self.preferencesWindowController.window];
    [self.preferencesWindowController willShow];
    if ([self isMainWindowVisible]) {
        [self.mainWindowController.window flipToWindow:self.preferencesWindowController.window withDuration:0.5 shadowed:NO];
    } else {
        [NSApp activateIgnoringOtherApps:YES];
        [self.preferencesWindowController.window makeKeyAndOrderFront:nil];
    }
}

- (void)hideMainWindow {
    [self.mainWindowController.window orderOut:nil];
}

- (void)hidePreferencesWindow {
    [self.preferencesWindowController.window orderOut:nil];
}

- (IBAction)toggleWindow:sender {
    if ([self isWindowVisible])
        [self hideWindow:sender];
    else
        [self displayWindow:sender];
}

- (IBAction)displayWindow:sender {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:PreferencesDoneKey]) {
        [self displayPreferencesWindow:sender];
    } else {
        [self displayMainWindow:sender];
    }
}

- (IBAction)hideWindow:sender {
    if ([self isMainWindowVisible])
        [self hideMainWindow];
    if ([self isPreferencesWindowVisible])
        [self hidePreferencesWindow];
}


#pragma mark -

- (void)considerShowingWindowOnAppStartup {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:PreferencesDoneKey]) {
        [self displayPreferencesWindow:nil];
    }
}


@end
