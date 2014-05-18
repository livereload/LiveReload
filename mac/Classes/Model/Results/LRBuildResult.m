
#import "LRBuildResult.h"

#import "Project.h"
#import "LRProjectFile.h"
#import "Glue.h"
#import "ATPathSpec.h"

#import "ATFunctionalStyle.h"


@interface LRBuildResult ()

@end


@implementation LRBuildResult {
    NSMutableArray *_modifiedFiles;
    NSMutableArray *_reloadRequests;
}

- (instancetype)initWithProject:(Project *)project {
    self = [super init];
    if (self) {
        _project = project;
        _reloadRequests = [NSMutableArray new];
        _modifiedFiles = [NSMutableArray new];
    }
    return self;
}

- (void)addReloadRequest:(NSDictionary *)reloadRequest {
    [_reloadRequests addObject:reloadRequest];
}

- (void)addModifiedFiles:(NSArray *)files {
    [_modifiedFiles addObjectsFromArray:files];
}

- (BOOL)hasReloadRequests {
    return _reloadRequests.count > 0;
}

- (void)sendReloadRequests {
    NSMutableArray *filesToReload = [_modifiedFiles mutableCopy];

    ATPathSpec *forcedStylesheetReloadSpec = _project.forcedStylesheetReloadSpec;
    if ([forcedStylesheetReloadSpec isNonEmpty]) {
        NSArray *filesTriggeringForcedStylesheetReloading = [filesToReload filteredArrayUsingBlock:^BOOL(LRProjectFile *file) {
            return [forcedStylesheetReloadSpec matchesPath:file.relativePath type:ATPathSpecEntryTypeFile];
        }];
        if (filesTriggeringForcedStylesheetReloading.count > 0) {
            [self addReloadRequest:@{@"path": @"force-reload-all-stylesheets.css", @"originalPath": [NSNull null]}];

            [filesToReload removeObjectsInArray:filesTriggeringForcedStylesheetReloading];
        }
    }

    for (LRProjectFile *file in filesToReload) {
        NSString *fullPath = file.absolutePath;
        [self addReloadRequest:@{@"path": fullPath, @"originalPath": [NSNull null], @"localPath": fullPath}];
    }

    if (_reloadRequests.count > 0) {
        [[Glue glue] postMessage:@{@"service": @"reloader", @"command": @"reload", @"changes": _reloadRequests, @"forceFullReload": @(_project.disableLiveRefresh), @"fullReloadDelay": @(_project.fullPageReloadDelay), @"enableOverride": @(_project.enableRemoteServerWorkflow)}];
    }
}

@end
