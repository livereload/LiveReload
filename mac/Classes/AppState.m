@import LRActionKit;

#import "AppState.h"
#import "Glue.h"
#import "Workspace.h"

#import "EditorManager.h"
#import "Preferences.h"

#import "LiveReload-Swift-x.h"
#import "Plugin.h"

@import PackageManagerKit;


static AppState *sharedAppState = nil;


@implementation AppState

+ (AppState *)sharedAppState {
    return sharedAppState;
}

+ (void)initializeAppState {
    sharedAppState = [AppState new];
    [sharedAppState _setup];
}

- (void)_setup {
    [self _setupCommandHandlers];

    _packageManager = [LRPackageManager new];

    _rubyRuntimeRepository = [[RubyRuntimeRepository alloc] init];

    _defaultRubyRuntimeReference = [self runtimeReferenceWithRepository:_rubyRuntimeRepository userDefaultsKey:@"defaultRubyRuntime"];

    [EditorManager sharedEditorManager];

    [Preferences initDefaults];

    // needs to happen before scanning for plugins
    [_packageManager addPackageType:[NpmPackageType new]];
    [_packageManager addPackageType:[GemPackageType new]];

    [ActionKitSingleton sharedActionKit].packageManager = [AppState sharedAppState].packageManager;
    [ActionKitSingleton sharedActionKit].postMessageBlock = ^(NSDictionary *message, ActionKitPostMessageCompletionBlock completionBlock) {
        [[Glue glue] postMessage:message withReplyHandler:completionBlock];
    };

    [[PluginManager sharedPluginManager] reloadPlugins];

    //        for (Plugin *plugin in [PluginManager sharedPluginManager].plugins) {
    //            plugin.
    //        }
}

- (void)finishLaunching {
    [_rubyRuntimeRepository load];
}

- (void)_setupCommandHandlers {
    [[Glue glue] registerCommand:@"kernel.server-connection-count-changed" syncHandler:^(NSDictionary *message, NSError **error) {
        self.numberOfConnectedBrowsers = [message[@"connectionCount"] integerValue];
        [Workspace sharedWorkspace].monitoringEnabled = (_numberOfConnectedBrowsers > 0);
    }];
    [[Glue glue] registerCommand:@"kernel.server-refresh-count-changed" syncHandler:^(NSDictionary *message, NSError **error) {
        self.numberOfRefreshesProcessed = [message[@"refreshCount"] integerValue];
    }];
}

- (RuntimeReference *)runtimeReferenceWithRepository:(RuntimeRepository *)repository userDefaultsKey:(NSString *)userDefaultsKey {
    RuntimeReference *reference = [[RuntimeReference alloc] initWithRepository:repository];
    reference.identifier = [[NSUserDefaults standardUserDefaults] stringForKey:userDefaultsKey] ?: @"system";

    __weak RuntimeReference *weakRef = reference;
    reference.identifierDidChangeBlock = ^{
        RuntimeReference *reference = weakRef;
        if (reference) {
            [[NSUserDefaults standardUserDefaults] setObject:reference.identifier forKey:userDefaultsKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    };

    return reference;
}

@end
