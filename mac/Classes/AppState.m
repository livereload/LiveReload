
#import "AppState.h"
#import "Glue.h"
#import "Workspace.h"

#import "EditorManager.h"
#import "Preferences.h"

#import "LiveReload-Swift-x.h"
#import "Plugin.h"

#import "LRPackageManager.h"
#import "NpmPackageType.h"
#import "GemPackageType.h"


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

    [EditorManager sharedEditorManager];

    [Preferences initDefaults];

    // needs to happen before scanning for plugins
    [_packageManager addPackageType:[NpmPackageType new]];
    [_packageManager addPackageType:[GemPackageType new]];

    [[PluginManager sharedPluginManager] reloadPlugins];

    //        for (Plugin *plugin in [PluginManager sharedPluginManager].plugins) {
    //            plugin.
    //        }
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

@end
