
#include "console.h"
#include "jansson.h"

#import "LiveReloadAppDelegate.h"
#import "Project.h"
#import "Workspace.h"
#import "CompilationOptions.h"
#import "StatusItemController.h"
#import "NewMainWindowController.h"
#import "ATLoginItemController.h"
#import "PluginManager.h"
#import "SandboxAccessModel.h"
#import "Glue.h"
#import "AppState.h"

#import "Stats.h"
#import "Preferences.h"
#import "LRGlobals.h"

#import "ShitHappens.h"
#import "LicenseManager.h"
#import "DockIcon.h"
#import "ATGlobals.h"
#import "NSData+Base64.h"
#import "Runtimes.h"
#import "EditorManager.h"
#import "ATFunctionalStyle.h"

#ifndef APPSTORE
#import "Glitter.h"
#import "GlitterUpdateInfoViewController.h"
#endif


@interface LiveReloadAppDelegate () <NSPopoverDelegate>

- (void)pingServer;
- (void)considerShowingWindowOnAppStartup;

- (BOOL)isMainWindowVisible;
- (void)hideMainWindow;

@end


@implementation LiveReloadAppDelegate {
    StatusItemController  *_statusItemController;
    NewMainWindowController  *_mainWindowController;
    int _port;
    Glitter *_glitter;

    id <NSObject> _activityToken;
    SandboxAccessModel *_sandboxAccessModel;
}


@synthesize statusItemController=_statusItemController;
@synthesize mainWindowController=_mainWindowController;
@synthesize port=_port;


#pragma mark - Launching

- (void)awakeFromNib {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [AppState initializeAppState];

    [[Glue glue] registerCommand:@"kernel.log" target:self action:@selector(handleLogMessage:)];
    [[Glue glue] registerCommand:@"kernel.on-port-occupied-error" target:self action:@selector(handlePortOccupied:)];
    [[Glue glue] registerCommand:@"kernel.on-browser-v6-protocol-connection" target:self action:@selector(handleVersion6Connection:)];

    _glitter = [[Glitter alloc] initWithMainBundle];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatusDidChange) name:GlitterStatusDidChangeNotification object:_glitter];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) { // OSX10.9+
        _activityToken = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiatedAllowingIdleSystemSleep reason:@"Background file monitoring"];
    }

    // initialize this early to allow the additional folders to be accessed by other initialization code
    _sandboxAccessModel = [[SandboxAccessModel alloc] initWithDataFileURL:[LRDataFolderURL() URLByAppendingPathComponent:@"sandbox-extensions.json"]];

    // Tell everyone we're running their scripts from LiveReload.
    // At least one of ours users has to test this var in his .bash_profile;
    // I can imagine there any many more cases when it comes in handy.
    putenv("INVOKED_FROM_LIVERELOAD=1");
    putenv("RUBYOPT=-Ku");

    [EditorManager sharedEditorManager];

    [Preferences initDefaults];
    [[PluginManager sharedPluginManager] reloadPlugins];

#ifndef APPSTORE
//    [[SUUpdater sharedUpdater] setDelegate:self];
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

    NSString *backendOverridePath = [NSProcessInfo processInfo].environment[@"LRBackendOverride"];
    if (backendOverridePath.length > 0) {
        NSURL *backendOverrideURL = [NSURL fileURLWithPath:backendOverridePath];

        [_sandboxAccessModel grantAccessToURL:[backendOverrideURL URLByDeletingLastPathComponent] writeAccess:NO title:@"Grant Access To Backend" message:@"Choose a **ROOT** folder of the overridden backend"];

        if (ATCheckPathAccessibility(backendOverrideURL) != ATPathAccessibilityAccessible) {
            [[NSAlert alertWithMessageText:@"LiveReload cannot access its backend" defaultButton:@"Quit" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Cannot read a file at the following path: %@", backendOverrideURL.path] runModal];
            exit(0);
        }
    }

    NSString *bundledPluginsOverridePath = [NSProcessInfo processInfo].environment[@"LRBundledPluginsOverride"];
    if (bundledPluginsOverridePath.length > 0) {
        NSURL *bundledPluginsOverrideURL = [NSURL fileURLWithPath:bundledPluginsOverridePath];

        [_sandboxAccessModel grantAccessToURL:bundledPluginsOverrideURL writeAccess:NO title:@"Grant Access To Bundled Plugins" message:@"Please confirm access to the bundled plugins"];

        if ( ATCheckPathAccessibility(bundledPluginsOverrideURL) != ATPathAccessibilityAccessible) {
            [[NSAlert alertWithMessageText:@"LiveReload cannot access its plugins" defaultButton:@"Quit" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Cannot access the following directory: %@", bundledPluginsOverrideURL.path] runModal];
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

    [[DockIcon currentDockIcon] displayDockIconWhenAppHasWindowsWithDelegateClass:[NewMainWindowController class]];

    [[[RubyRuntimeRepository alloc] init] load];
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
    @autoreleasepool {
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
    }
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
        // TODO: remove this, won't work with sandbox anyway
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


#pragma mark - Glitter

- (IBAction)checkForUpdates:(id)sender {
    [_glitter checkForUpdatesWithOptions:GlitterCheckOptionUserInitiated];
}

- (void)updateStatusDidChange {
    static NSString *lastVersion = nil;
    if (_glitter.readyToInstall) {
        NSString *version = _glitter.readyToInstallVersionDisplayName;
        if (lastVersion != nil && [lastVersion isEqualToString:version]) {
            return;
        }
        lastVersion = version;

        [[DockIcon currentDockIcon] setMenuBarIconVisibility:YES forRequestKey:@"update"];

        NSPopover *popover = [[NSPopover alloc] init];
        popover.contentViewController = [[GlitterUpdateInfoViewController alloc] initWithGlitter:_glitter];
        popover.behavior = NSPopoverBehaviorTransient;
        popover.delegate = self;
        [popover showRelativeToRect:CGRectZero ofView:_statusItemController.statusItemView preferredEdge:NSMaxYEdge];
    }
}

- (void)popoverDidClose:(NSNotification *)notification {
    [[DockIcon currentDockIcon] setMenuBarIconVisibility:NO forRequestKey:@"update"];
}


#pragma mark - Sandbox Access Extension

- (IBAction)extendSandboxForReadWriteAccess:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setTitle:@"Extend Sandbox"];
    [openPanel setMessage:@"Choose a folder that should be accessible to LiveReload"];
    [openPanel setPrompt:@"Allow Access"];
    [openPanel setCanChooseFiles:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];

    NSInteger result = [openPanel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        NSURL *url = [openPanel URL];

        [_sandboxAccessModel addURL:url];
    }
}

- (IBAction)showSandboxExtensions:(id)sender {
    NSArray *urls = [_sandboxAccessModel.accessibleURLs arrayByMappingElementsUsingBlock:^id(NSURL *url) {
        return [NSString stringWithFormat:@"• %@", url.path];
    }];

    NSAlert *alert = [NSAlert new];
    [alert setMessageText:@"Accessible URLs"];
    [alert setInformativeText:[NSString stringWithFormat:@"The following URLs have been manually added to the LiveReload sandbox:\n\n%@", [urls componentsJoinedByString:@"\n"]]];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}


#pragma mark - Commands

- (void)handleLogMessage:(NSDictionary *)message {
    NSLog(@"[Node %@] %@", message[@"level"], message[@"text"]);
}

- (void)handlePortOccupied:(NSDictionary *)message {
    int port = [message[@"port"] intValue];

    NSInteger response = [[NSAlert alertWithMessageText:@"Failed to start: port occupied" defaultButton:@"Quit" alternateButton:@"More Info" otherButton:nil informativeTextWithFormat:@"LiveReload tried to listen on port %d, but it was occupied by another app.\n\nThe following tools are incompatible with LiveReload: guard-livereload; rack-livereload; Sublime Text LiveReload plugin; any other tools that use LiveReload browser extensions.\n\nPlease make sure you're not running any of those tools, and restart LiveReload. If in doubt, contact support@livereload.com.", port] runModal];
    if (response == NSAlertAlternateReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://go.livereload.com/err/port-occupied"]];
    }
    [NSApp terminate:nil];
}

- (void)handleVersion6Connection:(NSDictionary *)message {
    NSInteger response = [[NSAlert alertWithMessageText:@"Legacy browser extensions" defaultButton:@"Update Now" alternateButton:@"Ignore" otherButton:nil informativeTextWithFormat:@"LiveReload browser extensions 1.x are no longer supported and won't work with LiveReload 2.\n\nPlease update your browser extensions to version 2.x to get advantage of many bug fixes, automatic reconnection, @import support, in-browser LESS.js support and more."] runModal];
    if (response == NSAlertAlternateReturn) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://go.livereload.com/err/port-occupied"]];
    }
}

@end
