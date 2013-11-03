
#import "AppState.h"
#import "Glue.h"
#import "Workspace.h"

#import "LRPackageManager.h"
#import "NpmPackageType.h"


static AppState *sharedAppState = nil;


@implementation AppState

+ (AppState *)sharedAppState {
    return sharedAppState;
}

+ (void)initializeAppState {
    sharedAppState = [AppState new];
}

- (id)init {
    self = [super init];
    if (self) {
        [self _setupCommandHandlers];

        _packageManager = [LRPackageManager new];
        [_packageManager addPackageType:[NpmPackageType new]];
    }
    return self;
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
