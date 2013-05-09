
#include "console.h"
#include "jansson.h"
#include "nodeapp_rpc_proxy.h"

#import "LiveReloadAppDelegate.h"
#import "Project.h"
#import "Workspace.h"
#import "CompilationOptions.h"
#import "StatusItemController.h"
#import "NewMainWindowController.h"
#import "LoginItemController.h"
#import "PluginManager.h"

#import "Stats.h"
#import "NSWindowFlipper.h"
#import "Preferences.h"

#import "ShitHappens.h"
#import "FixUnixPath.h"
#import "LicenseManager.h"
#import "DockIcon.h"
#import "ATSandboxing.h"
#import "NSData+Base64.h"
#import "RubyRuntimes.h"

#ifndef APPSTORE
#import "Sparkle/Sparkle.h"
#endif


void C_mainwnd__set_project_list(json_t *arg) {
    // TODO
}

void C_mainwnd__rpane__set_data(json_t *arg) {
    // TODO
}

void C_app__good_time_to_deliver_news(json_t *arg) {
    AppNewsKitGoodTimeToDeliverMessages();
}

void C_update(json_t *arg) {
    // ignored for compatibility with the Windows version
}


@interface LiveReloadAppDelegate ()

- (void)pingServer;
- (void)considerShowingWindowOnAppStartup;

- (BOOL)isMainWindowVisible;
- (void)hideMainWindow;

@end


@implementation LiveReloadAppDelegate

@synthesize statusItemController=_statusItemController;
@synthesize mainWindowController=_mainWindowController;
@synthesize port=_port;


#pragma mark - Launching

- (void)awakeFromNib {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Tell everyone we're running their scripts from LiveReload.
    // At least one of ours users has to test this var in his .bash_profile;
    // I can imagine there any many more cases when it comes in handy.
    putenv("INVOKED_FROM_LIVERELOAD=1");

    [Preferences initDefaults];
    [[PluginManager sharedPluginManager] reloadPlugins];

#ifndef APPSTORE
    [[SUUpdater sharedUpdater] setDelegate:self];
#endif

    _port = 35729;
    if (getenv("LRPortOverride")) {
        _port = atoi(getenv("LRPortOverride"));
    } else {
        int overridePort = (int) [[NSUserDefaults standardUserDefaults] integerForKey:@"HttpPort"];
        if (overridePort != 0) {
            setenv("LRPortOverride", [[NSString stringWithFormat:@"%d", overridePort] UTF8String], 1);
            _port = overridePort;
        }
    }

    const char *backendOverrideRaw = getenv("LRBackendOverride");
    if (backendOverrideRaw && *backendOverrideRaw) {
        NSString *backendOverride = [NSString stringWithUTF8String:backendOverrideRaw];
        NSError *error = nil;

        if (ATIsSandboxed()) {
            BOOL stale = NO;
            NSString *bookmark = [[NSUserDefaults standardUserDefaults] stringForKey:@"BackendOverrideBookmark"];
            if ([bookmark length] > 0) {
                NSURL *url = [NSURL URLByResolvingBookmarkData:[NSData dataFromBase64String:bookmark] options:NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&stale error:&error];
                if (url) {
                    [url startAccessingSecurityScopedResource];
                }
            }

            NSString *data = [NSString stringWithContentsOfFile:backendOverride encoding:NSUTF8StringEncoding error:NULL];
            if (!data) {
                // chances are we don't have access
                NSOpenPanel *openPanel = [NSOpenPanel openPanel];
                [openPanel setCanChooseDirectories:YES];
                [openPanel setCanCreateDirectories:NO];
                [openPanel setTitle:@"Grant Access To Backend"];
                [openPanel setMessage:@"Choose a root folder of the overridden backend"];
                [openPanel setPrompt:@"Extend Sandbox"];
                [openPanel setCanChooseFiles:NO];
                [openPanel setTreatsFilePackagesAsDirectories:YES];
                NSInteger result = [openPanel runModal];
                if (result == NSFileHandlingPanelOKButton) {
                    NSURL *url = [openPanel URL];

                    bookmark = [[url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope|NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:&error] base64EncodedString];
                    if (bookmark) {
                        [[NSUserDefaults standardUserDefaults] setObject:bookmark forKey:@"BackendOverrideBookmark"];
                    }
                }
            }
        }

        NSString *data = [NSString stringWithContentsOfFile:backendOverride encoding:NSUTF8StringEncoding error:NULL];
        if (!data) {
            [[NSAlert alertWithMessageText:@"LiveReload cannot access its backend" defaultButton:@"Quit" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Cannot read a file at the following path: %@", backendOverride] runModal];
            exit(0);
        }
    }

    [super applicationDidFinishLaunching:aNotification];

    _statusItemController = [[StatusItemController alloc] init];
    [self.statusItemController initStatusBarIcon];

    _mainWindowController = [[NewMainWindowController alloc] init];

    console_init();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self considerShowingWindowOnAppStartup];

        AppNewsKitSetStringValue(@"platform", @"mac");
#ifdef APPSTORE
        AppNewsKitSetStringValue(@"status", @"appstore");
#else
        AppNewsKitSetStringValue(@"status", @"beta");
#endif
        AppNewsKitSetStringValue(@"userplugins", [[PluginManager sharedPluginManager].userPluginNames componentsJoinedByString:@","]);
        AppNewsKitStartup(@"http://livereload.com/ping.php", ^(NSMutableDictionary *params) {
            [params setObject:[[Preferences sharedPreferences].additionalExtensions componentsJoinedByString:@","] forKey:@"exts"];
        });
//        [self pingServer];
        [NSTimer scheduledTimerWithTimeInterval:60*60*24 target:self selector:@selector(pingServer) userInfo:nil repeats:YES];
    });

    FixUnixPath();

    [[DockIcon currentDockIcon] displayDockIconWhenAppHasWindowsWithDelegateClass:[NewMainWindowController class]];

    [[RubyManager alloc] init];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    AppNewsKitGoodTimeToDeliverMessages();
}

- (void)applicationDidResignActive:(NSNotification *)notification {
    AppNewsKitGoodTimeToDeliverMessages();
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename isDirectory:&isDirectory]) {
        if (isDirectory) {
            Project *project = [[Workspace sharedWorkspace] projectWithPath:filename create:YES];
            [self projectAdded:project];
            return YES;
        }
    }
    return NO;
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
    AppNewsKitGoodTimeToDeliverMessages();
}

- (void)hideMainWindow {
    [self.mainWindowController close];
}

- (IBAction)toggleMainWindow:sender {
    if ([self isMainWindowVisible])
        [self hideMainWindow];
    else
        [self displayMainWindow:sender];
}

- (void)considerShowingWindowOnAppStartup {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunchDone"]) {
        [self displayMainWindow:self];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"firstLaunchDone"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (![self isMainWindowVisible])
        [self displayMainWindow:nil];
    return NO;
}


#pragma mark - Model

- (void)projectAdded:(Project *)project {
    if (![self isMainWindowVisible])
        [self displayMainWindow:nil];
    [self.mainWindowController projectAdded:project];
}

- (void)addProjectAtPath:(NSString *)path {
    [self addProjectsAtPaths:[NSArray arrayWithObject:path]];
}

- (void)addProjectsAtPaths:(NSArray *)paths {
    Project *newProject = nil;
    for (NSString *path in paths) {
        newProject = [[Workspace sharedWorkspace] projectWithPath:path create:YES];
    }
    [[NSApp delegate] displayMainWindow:nil];
    if ([paths count] == 1) {
        [self projectAdded:newProject];
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
//                        CompilationOptions *options = [project optionsForCompiler:compiler create:YES];
//                        options.mode = CompilationModeFromNSString(mode);
                    }
                } else {
                    NSLog(@"Ignoring options for unknown compiler: '%@'", compilerId);
                }
            }

            [self projectAdded:project];
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


#pragma mark - Sparkle

- (IBAction)checkForUpdates:(id)sender {
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
}

@end
