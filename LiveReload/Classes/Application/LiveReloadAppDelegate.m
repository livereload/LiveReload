
#import "LiveReloadAppDelegate.h"
#import "Project.h"
#import "Workspace.h"
#import "CompilationOptions.h"
#import "StatusItemController.h"
#import "MainWindowController.h"
#import "PreferencesWindowController.h"
#import "CommunicationController.h"
#import "LoginItemController.h"
#import "PluginManager.h"

#import "Stats.h"
#import "NSWindowFlipper.h"
#import "Preferences.h"

@interface LiveReloadAppDelegate ()

- (void)pingServer;
- (void)considerShowingWindowOnAppStartup;

- (BOOL)isMainWindowVisible;
- (void)hideMainWindow;

@end


@implementation LiveReloadAppDelegate

@synthesize statusItemController=_statusItemController;
@synthesize mainWindowController=_mainWindowController;
@synthesize preferencesWindowController = _preferencesWindowController;

- (void)awakeFromNib {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

// just to make XDry happy; won't ever be deallocated
- (void)dealloc {
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSDate *now = [NSDate date];
    NSDateComponents *cutoff = [[[NSDateComponents alloc] init] autorelease];
    [cutoff setYear:2011];
    [cutoff setMonth:12];
    [cutoff setDay:1];
    if ([now compare:[[NSCalendar currentCalendar] dateFromComponents:cutoff]] == NSOrderedDescending) {
        // stop auto-login and show a message
        NSInteger ans = [[NSAlert alertWithMessageText:@"LiveReload 2 beta has expired"
                                         defaultButton:@"Visit our site"
                                       alternateButton:@"Quit LiveReload"
                                           otherButton:nil
                             informativeTextWithFormat:@"Sorry, this beta version of LiveReload has expired and cannot be launched.\n\nPlease visit http://livereload.mockko.com/ to get an updated version."] runModal];
        if (ans == NSAlertDefaultReturn) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://livereload.com/"]];
        } else {
            [LoginItemController sharedController].loginItemEnabled = NO;
        }
        [NSApp terminate:self];
    }

    [Preferences initDefaults];
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
    if ([self isMainWindowVisible] && ![self.mainWindowController isProjectOptionsSheetVisible]) {
        [self hideMainWindow];
    }
}

- (void)pingServer {
    [self performSelectorInBackground:@selector(pingServerInBackground) withObject:nil];
}

- (void)pingServerInBackground {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *internalVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:version forKey:@"v"];
    [params setObject:internalVersion forKey:@"iv"];

    StatAllToParams(params);

    NSMutableString *qs = [NSMutableString string];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([qs length] > 0)
            [qs appendString:@"&"];
        [qs appendFormat:@"%@=%@", key, [obj stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }];

    [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://livereload.com/ping.php?%@", qs]]];
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

+ (NSSet *)keyPathsForValuesAffectingWindowVisible {
    return [NSSet setWithObjects:@"mainWindowVisible", @"preferencesWindowVisible", nil];
}

- (IBAction)displayMainWindow:sender {
    [self willChangeValueForKey:@"mainWindowVisible"];
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
    [self didChangeValueForKey:@"mainWindowVisible"];
}

- (IBAction)displayPreferencesWindow:sender {
    [self willChangeValueForKey:@"preferencesWindowVisible"];
    [self positionWindow:self.preferencesWindowController.window];
    [self.preferencesWindowController willShow];
    if ([self isMainWindowVisible]) {
        [self.mainWindowController.window flipToWindow:self.preferencesWindowController.window withDuration:0.5 shadowed:NO];
    } else {
        [NSApp activateIgnoringOtherApps:YES];
        [self.preferencesWindowController.window makeKeyAndOrderFront:nil];
    }
    [self didChangeValueForKey:@"preferencesWindowVisible"];
}

- (void)hideMainWindow {
    [self willChangeValueForKey:@"mainWindowVisible"];
    [self.mainWindowController.window orderOut:nil];
    [self didChangeValueForKey:@"mainWindowVisible"];
}

- (void)hidePreferencesWindow {
    [self willChangeValueForKey:@"preferencesWindowVisible"];
    [self.preferencesWindowController.window orderOut:nil];
    [self didChangeValueForKey:@"preferencesWindowVisible"];
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


#pragma mark -

- (IBAction)sendFeedback:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://help.livereload.com/discussion/new"]];
}


#pragma mark -

- (void)handleCommand:(NSString *)command params:(NSDictionary *)params {
    NSLog(@"Received command %@ with params %@", command, params);
    if ([command isEqualToString:@"add"]) {
        NSString *path = [[[params objectForKey:@"path"] stringByExpandingTildeInPath] stringByStandardizingPath];
        BOOL isDir = NO;
        if (path && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
            Project *project = [[Workspace sharedWorkspace] projectWithPath:path create:YES];

            NSMutableSet *compilerIds = [NSMutableSet set];
            [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSString *prefix = @"compiler-";
                if ([key length] > [prefix length] && [[key substringToIndex:[prefix length]] isEqualToString:prefix]) {
                    NSString *compilerId = [key substringFromIndex:[prefix length]];
                    NSRange r = [compilerId rangeOfString:@"-" options:NSBackwardsSearch];
                    if (r.length > 0) {
                        compilerId = [compilerId substringToIndex:r.location];
                        [compilerIds addObject:compilerId];
                    }
                }
            }];

            for (NSString *compilerId in compilerIds) {
                Compiler *compiler = [[PluginManager sharedPluginManager] compilerWithUniqueId:compilerId];
                if (compiler) {
                    NSString *mode = [params objectForKey:[NSString stringWithFormat:@"compiler-%@-mode", compilerId]];
                    if ([mode length] > 0) {
                        CompilationOptions *options = [project optionsForCompiler:compiler create:YES];
                        options.mode = CompilationModeFromNSString(mode);
                    }
                } else {
                    NSLog(@"Ignoring options for unknown compiler: '%@'", compilerId);
                }
            }
        } else {
            NSLog(@"Refusing to add '%@' -- the directory does not exist.", path);
        }
    } else if ([command isEqualToString:@"remove"]) {
        NSString *path = [[[params objectForKey:@"path"] stringByExpandingTildeInPath] stringByStandardizingPath];
        Project *project = [[Workspace sharedWorkspace] projectWithPath:path create:NO];
        if (project) {
            [[Workspace sharedWorkspace] removeProjectsObject:project];
        } else {
            NSLog(@"Could not find an existing project at '%@'", path);
        }
    }
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent {
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSString *prefix = @"livereload:";
    if ([url length] < [prefix length] || ![[url substringToIndex:[prefix length]] isEqualToString:prefix])
        return;
    url = [url substringFromIndex:[prefix length]];

    NSRange range = [url rangeOfString:@"?"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *command;
    if (range.length > 0) {
        command = [url substringToIndex:range.location];
        NSString *query = [url substringFromIndex:range.location+1];
        [[query componentsSeparatedByString:@"&"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSRange eq = [obj rangeOfString:@"="];
            if (eq.length > 0) {
                NSString *key = [obj substringToIndex:eq.location];
                NSString *value = [[obj substringFromIndex:eq.location + 1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [params setObject:value forKey:key];
            }
        }];
    } else {
        command = url;
    }
    [self handleCommand:command params:params];
}

@end
