
#import "LRBuildResult.h"

#import "Project.h"
#import "LRProjectFile.h"
#import "LRTargetResult.h"
#import "ActionType.h"

#import "Glue.h"
#import "Stats.h"

#import "ATPathSpec.h"
#import "ATFunctionalStyle.h"


NSString *const LRBuildDidFinishNotification = @"LRBuildDidFinishNotification";


@interface LRBuildResult ()

@end


@implementation LRBuildResult {
    NSMutableArray *_modifiedFiles;
    NSMutableSet *_modifiedFilesSet;
    NSMutableArray *_reloadRequests;
    NSMutableSet *_compiledFiles;

    NSMutableArray *_pendingFileTargets;
    NSMutableArray *_pendingProjectTargets;

    LRTargetResult *_runningTarget;
    BOOL _waitingForMoreChangesBeforeFinishing;

    NSTimeInterval _gracePeriodWithoutReloadRequests;
    NSTimeInterval _gracePeriodWithReloadRequests;
}

- (instancetype)initWithProject:(Project *)project actions:(NSArray *)actions {
    self = [super init];
    if (self) {
        _project = project;
        _actions = [actions copy];

        _reloadRequests = [NSMutableArray new];
        _modifiedFiles = [NSMutableArray new];
        _modifiedFilesSet = [NSMutableSet new];
        _compiledFiles = [NSMutableSet new];
        _pendingFileTargets = [NSMutableArray new];
        _pendingProjectTargets = [NSMutableArray new];

        _gracePeriodWithoutReloadRequests = 0.25;
        _gracePeriodWithReloadRequests = 0.05;
    }
    return self;
}

- (void)addReloadRequest:(NSDictionary *)reloadRequest {
    [_reloadRequests addObject:reloadRequest];
}

- (void)addModifiedFiles:(NSArray *)files {
    NSMutableArray *newFiles = [NSMutableArray new];
    for (LRProjectFile *file in files) {
        // TODO: add a duplicate target if the previous one has already been completed
        if (![_modifiedFilesSet containsObject:file]) {
            [newFiles addObject:file];
        }
    }

    if (newFiles.count > 0) {
        [_modifiedFilesSet addObjectsFromArray:newFiles];
        [_modifiedFiles addObjectsFromArray:newFiles];

        for (Action *action in _actions) {
            [_pendingFileTargets addObjectsFromArray:[action fileTargetsForModifiedFiles:newFiles]];
        }

//    [_pendingProjectTargets addObjectsFromArray:[_actions arrayByMappingElementsUsingBlock:^id(Action *action) {
//        return [action targetForModifiedFiles:_modifiedFiles];
//    }]];

        if (_waitingForMoreChangesBeforeFinishing) {
            [self executeNextTarget];
        }
    }
}


#pragma mark - Reload requests

- (BOOL)hasReloadRequests {
    return _reloadRequests.count > 0;
}

- (void)markAsConsumedByCompiler:(LRProjectFile *)file {
    [_compiledFiles addObject:file];
}

- (void)updateReloadRequests {
    [_reloadRequests removeAllObjects];

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
        if ([_compiledFiles containsObject:file]) {
            continue;  // compiled; wait for the destination file change event to send a reload request
        }

        NSString *fakeDestinationName = [[[_project compilerActionTypesForFile:file] arrayByMappingElementsUsingBlock:^id(ActionType *actionType) {
            return [actionType fakeChangeDestinationNameForSourceFile:file];
        }] firstObject];

        NSString *fullPath = file.absolutePath;
        if (fakeDestinationName) {
            NSString *fakePath = [[fullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fakeDestinationName];
            [self addReloadRequest:@{@"path": fakePath, @"originalPath": fullPath, @"localPath": [NSNull null]}];
        } else {
            [self addReloadRequest:@{@"path": fullPath, @"originalPath": [NSNull null], @"localPath": fullPath}];
        }
    }
}

- (void)sendReloadRequests {
    [self updateReloadRequests];

    if (_reloadRequests.count > 0) {
        [[Glue glue] postMessage:@{@"service": @"reloader", @"command": @"reload", @"changes": _reloadRequests, @"forceFullReload": @(_project.disableLiveRefresh), @"fullReloadDelay": @(_project.fullPageReloadDelay), @"enableOverride": @(_project.enableRemoteServerWorkflow)}];
        [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidDetectChangeNotification object:self];
        StatIncrement(BrowserRefreshCountStat, 1);
    }
}


#pragma mark - Lifecycle

- (void)start {
    if (_started)
        return;
    _started = YES;

    [self executeNextTarget];
}

- (void)finish {
    if (_finished)
        return;

    _finished = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:LRBuildDidFinishNotification object:self];
}


#pragma mark - Execution

- (void)executeNextTarget {
    if (_runningTarget)
        return;

    if (_waitingForMoreChangesBeforeFinishing) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(gracePeriodExpired) object:nil];
        _waitingForMoreChangesBeforeFinishing = NO;
    }

    LRTargetResult *target = [_pendingFileTargets lastObject];
    if (target) {
        [_pendingFileTargets removeLastObject];
    } else {
        target = [_pendingProjectTargets firstObject];
        if (target) {
            [_pendingProjectTargets removeObjectAtIndex:0];
        }
    }

    if (target) {
        [self executeTarget:target];
    } else {
        [self updateReloadRequests];
        NSTimeInterval gracePeriod = ([self hasReloadRequests] ? _gracePeriodWithReloadRequests : _gracePeriodWithoutReloadRequests);

        [self performSelector:@selector(gracePeriodExpired) withObject:nil afterDelay:gracePeriod];
        _waitingForMoreChangesBeforeFinishing = YES;
    }
}

- (void)gracePeriodExpired {
    _waitingForMoreChangesBeforeFinishing = NO;
    [self finish];
}

- (void)executeTarget:(LRTargetResult *)target {
    _runningTarget = target;
    [target invokeWithCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            _runningTarget = nil;
            [self executeNextTarget];
        });
    } build:self];
}

- (void)addOperationResult:(LROperationResult *)result forTarget:(LRTargetResult *)target key:(NSString *)key {
    [self.project displayResult:result key:key];
}

@end
