
#import "LRBuildResult.h"

#import "Project.h"
#import "Glue.h"


@interface LRBuildResult ()

@end


@implementation LRBuildResult {
    NSMutableArray *_reloadRequests;
}

- (instancetype)initWithProject:(Project *)project {
    self = [super init];
    if (self) {
        _project = project;
        _reloadRequests = [NSMutableArray new];
    }
    return self;
}

- (void)addReloadRequest:(NSDictionary *)reloadRequest {
    [_reloadRequests addObject:reloadRequest];
}

- (BOOL)hasReloadRequests {
    return _reloadRequests.count > 0;
}

- (void)sendReloadRequests {
    if (_reloadRequests.count > 0) {
        [[Glue glue] postMessage:@{@"service": @"reloader", @"command": @"reload", @"changes": _reloadRequests, @"forceFullReload": @(_project.disableLiveRefresh), @"fullReloadDelay": @(_project.fullPageReloadDelay), @"enableOverride": @(_project.enableRemoteServerWorkflow)}];
    }
}

@end
