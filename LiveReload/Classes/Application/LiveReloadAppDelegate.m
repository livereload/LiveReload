
#import "LiveReloadAppDelegate.h"
#import "Project.h"
#import "Workspace.h"
#import "CompilationOptions.h"
#import "StatusItemController.h"
#import "NewMainWindowController.h"
#import "PreferencesWindowController.h"
#import "CommunicationController.h"
#import "LoginItemController.h"
#import "PluginManager.h"

#import "Stats.h"
#import "NSWindowFlipper.h"
#import "Preferences.h"

#import "ShitHappens.h"
#import "FixUnixPath.h"


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


#pragma mark - Launching

- (void)awakeFromNib {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
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
                             informativeTextWithFormat:@"Sorry, this beta version of LiveReload has expired and cannot be launched.\n\nPlease visit http://livereload.com/ to get an updated version."] runModal];
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

    _mainWindowController = [[NewMainWindowController alloc] init];
    _preferencesWindowController = [[PreferencesWindowController alloc] init];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

        [[CommunicationController sharedCommunicationController] startServer];

        [self considerShowingWindowOnAppStartup];

        [self pingServer];
        [NSTimer scheduledTimerWithTimeInterval:60*60*24 target:self selector:@selector(pingServer) userInfo:nil repeats:YES];
    });

    FixUnixPath();
}


#pragma mark - Pinging server

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

    [params setObject:[[Preferences sharedPreferences].additionalExtensions componentsJoinedByString:@","] forKey:@"exts"];

    NSMutableString *qs = [NSMutableString string];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([qs length] > 0)
            [qs appendString:@"&"];
        [qs appendFormat:@"%@=%@", key, [obj stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }];

    [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://livereload.com/ping.php?%@", qs]]];
    [pool drain];
}


#pragma mark - Main window

- (BOOL)isMainWindowVisible {
    return [NSApp isActive] && [_mainWindowController isWindowLoaded] && [_mainWindowController.window isVisible];
}

- (IBAction)displayMainWindow:sender {
    [NSApp activateIgnoringOtherApps:YES];
    [_mainWindowController showWindow:nil];
    [_mainWindowController.window makeKeyAndOrderFront:nil];
}

- (void)hideMainWindow {
    [self.mainWindowController.window orderOut:nil];
}

- (IBAction)toggleMainWindow:sender {
    if ([self isMainWindowVisible])
        [self hideMainWindow];
    else
        [self displayMainWindow:sender];
}

- (void)considerShowingWindowOnAppStartup {
    // TODO: show the window on first launch, and restore window visibility on subsequent launches
}


#pragma mark - Model

- (void)addProjectAtPath:(NSString *)path {
    [self addProjectsAtPaths:[NSArray arrayWithObject:path]];
}

- (void)addProjectsAtPaths:(NSArray *)paths {
    Project *newProject = nil;
    for (NSString *path in paths) {
        newProject = [[[Project alloc] initWithPath:path memento:nil] autorelease];
        [[Workspace sharedWorkspace] addProjectsObject:newProject];
    }
    [[NSApp delegate] displayMainWindow:nil];
    if ([paths count] == 1) {
        [self.mainWindowController projectAdded:newProject];
    }
}


#pragma mark - Preferences


- (IBAction)displayPreferencesWindow:sender {
    [self.preferencesWindowController willShow];
    if ([self isMainWindowVisible]) {
        [self.mainWindowController.window flipToWindow:self.preferencesWindowController.window withDuration:0.5 shadowed:NO];
    } else {
        [NSApp activateIgnoringOtherApps:YES];
        [self.preferencesWindowController.window makeKeyAndOrderFront:nil];
    }
}


#pragma mark - Help and support

- (IBAction)openSupport:(id)sender {
    TenderStartDiscussion(@"", @"");
}

- (IBAction)openHelp:(id)sender {
    TenderDisplayHelp();
}


#pragma mark - URL API

- (void)handleCommand:(NSString *)command params:(NSDictionary *)params {
    NSLog(@"Received command %@ with params %@", command, params);
    if ([command isEqualToString:@"add"]) {
        NSString *path = [[[params objectForKey:@"path"] stringByExpandingTildeInPath] stringByStandardizingPath];
        BOOL isDir = NO;
        if (path && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
//            Project *project = [[Workspace sharedWorkspace] projectWithPath:path create:YES];

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
//                        CompilationOptions *options = [project optionsForCompiler:compiler create:YES];
//                        options.mode = CompilationModeFromNSString(mode);
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
