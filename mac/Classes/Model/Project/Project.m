
#import "ToolOutputWindowController.h"
#import "ATGlobals.h"

#import "PluginManager.h"

#import "Project.h"
#import "OldFSMonitor.h"
#import "OldFSTreeFilter.h"
#import "OldFSTree.h"
#import "Preferences.h"
#import "PluginManager.h"
#import "Compiler.h"
#import "LegacyCompilationOptions.h"
#import "LRProjectFile.h"
#import "ImportGraph.h"
#import "ToolOutput.h"
#import "UserScript.h"
#import "FilterOption.h"
#import "Glue.h"
#import "LRPackageResolutionContext.h"
#import "ATPathSpec.h"
#import "LRBuildResult.h"
#import "LRTargetResult.h"
#import "LROperationResult.h"
#import "LRMessage.h"

#import "Stats.h"
#import "RegexKitLite.h"
#import "NSArray+ATSubstitutions.h"
#import "NSTask+OneLineTasksWithOutput.h"
#import "ATFunctionalStyle.h"
#import "P2AsyncEnumeration.h"
#import "ATObservation.h"
#import "LRCommandLine.h"

#include <stdbool.h>
#include "common.h"
#include "sglib.h"
#include "console.h"
#include "stringutil.h"
#include "eventbus.h"


#define PathKey @"path"

#define DefaultPostProcessingGracePeriod 0.5

NSString *ProjectDidDetectChangeNotification = @"ProjectDidDetectChangeNotification";
NSString *ProjectWillBeginCompilationNotification = @"ProjectWillBeginCompilationNotification";
NSString *ProjectDidEndCompilationNotification = @"ProjectDidEndCompilationNotification";
NSString *ProjectMonitoringStateDidChangeNotification = @"ProjectMonitoringStateDidChangeNotification";
NSString *ProjectNeedsSavingNotification = @"ProjectNeedsSavingNotification";
NSString *ProjectAnalysisDidFinishNotification = @"ProjectAnalysisDidFinishNotification";
NSString *ProjectBuildFinishedNotification = @"ProjectBuildFinishedNotification";

static NSString *CompilersEnabledMonitoringKey = @"someCompilersEnabled";



BOOL MatchLastPathComponent(NSString *path, NSString *lastComponent) {
    return [[path lastPathComponent] isEqualToString:lastComponent];
}

BOOL MatchLastPathTwoComponents(NSString *path, NSString *secondToLastComponent, NSString *lastComponent) {
    NSArray *components = [path pathComponents];
    return components.count >= 2 && [[components objectAtIndex:components.count - 2] isEqualToString:secondToLastComponent] && [[path lastPathComponent] isEqualToString:lastComponent];
}



@interface Project () <FSMonitorDelegate>

- (void)updateFilter;
- (void)handleCompilationOptionsEnablementChanged;

- (void)updateImportGraphForPaths:(NSSet *)paths;
- (void)rebuildImportGraph;

- (void)processPendingChanges;

@end


@implementation Project {
    NSURL                   *_rootURL;
    NSString                *_path;
    BOOL                     _accessible;
    BOOL                     _accessingSecurityScopedResource;

    FSMonitor *_monitor;

    BOOL _clientsConnected;
    BOOL                    _enabled;

    NSMutableSet            *_monitoringRequests;

    NSString                *_lastSelectedPane;
    BOOL                     _dirty;

    NSTimeInterval           _postProcessingGracePeriod;

    NSString                *_rubyVersionIdentifier;

    NSMutableDictionary     *_legacyCompilationOptions;

    BOOL                     _legacyCompilationEnabled;
    NSString                *_legacyPostProcessingCommand;
    BOOL                     _legacyPostProcessingEnabled;

    ImportGraph             *_importGraph;
    BOOL                     _compassDetected;

    BOOL                     _disableLiveRefresh;
    BOOL                     _enableRemoteServerWorkflow;
    NSTimeInterval           _fullPageReloadDelay;
    NSTimeInterval           _eventProcessingDelay;

    BOOL                     _brokenPathReported;

    NSMutableArray          *_excludedFolderPaths;

    NSInteger                _numberOfPathComponentsToUseAsName;
    NSString                *_customName;

    NSArray                 *_urlMasks;

    NSMutableSet            *_pendingChanges;
    BOOL                     _processingChanges;

    BOOL                     _runningPostProcessor;
    BOOL                     _pendingPostProcessing;
    NSTimeInterval           _lastPostProcessingRunDate;

    NSInteger                _buildsRunning;
    LRBuildResult           *_runningBuild;
    LRBuildResult           *_lastFinishedBuild;

    NSMutableDictionary     *_fileDatesHack;

    NSMutableSet            *_runningAnalysisTasks;

    BOOL                     _quuxMode;
    ATPathSpec              *_forcedStylesheetReloadSpec;
}

@synthesize path=_path;
@synthesize dirty=_dirty;
@synthesize lastSelectedPane=_lastSelectedPane;
@synthesize enabled=_enabled;
@synthesize disableLiveRefresh=_disableLiveRefresh;
@synthesize enableRemoteServerWorkflow=_enableRemoteServerWorkflow;
@synthesize fullPageReloadDelay=_fullPageReloadDelay;
@synthesize eventProcessingDelay=_eventProcessingDelay;
@synthesize postProcessingGracePeriod=_postProcessingGracePeriod;
@synthesize rubyVersionIdentifier=_rubyVersionIdentifier;
@synthesize numberOfPathComponentsToUseAsName=_numberOfPathComponentsToUseAsName;
@synthesize customName=_customName;
@synthesize urlMasks=_urlMasks;


#pragma mark -
#pragma mark Init/dealloc

- (id)initWithURL:(NSURL *)rootURL memento:(NSDictionary *)memento {
    if ((self = [super init])) {
        _rootURL = rootURL;
        [self _updateValuesDerivedFromRootURL];

        _enabled = YES;

        _fileDatesHack = [NSMutableDictionary new];

        _legacyCompilationOptions = [[NSMutableDictionary alloc] init];
        _monitoringRequests = [[NSMutableSet alloc] init];
        _runningAnalysisTasks = [NSMutableSet new];

        _resolutionContext = [[LRPackageResolutionContext alloc] init];

        _actionList = [[ActionList alloc] initWithActionTypes:[PluginManager sharedPluginManager].actionTypes project:self];
        [_actionList setMemento:memento];

        _lastSelectedPane = [[memento objectForKey:@"last_pane"] copy];

        id raw = [memento objectForKey:@"compilers"];
        if (raw) {
            PluginManager *pluginManager = [PluginManager sharedPluginManager];
            [raw enumerateKeysAndObjectsUsingBlock:^(id uniqueId, id compilerMemento, BOOL *stop) {
                Compiler *compiler = [pluginManager compilerWithUniqueId:uniqueId];
                if (compiler) {
                    [_legacyCompilationOptions setObject:[[LegacyCompilationOptions alloc] initWithCompiler:compiler memento:compilerMemento] forKey:uniqueId];
                } else {
                    // TODO: save data for unknown compilers and re-add them when creating a memento
                }
            }];
        }

        if ([memento objectForKey:@"compilationEnabled"]) {
            _legacyCompilationEnabled = [[memento objectForKey:@"compilationEnabled"] boolValue];
        } else {
            _legacyCompilationEnabled = NO;
        }

        _disableLiveRefresh = [[memento objectForKey:@"disableLiveRefresh"] boolValue];
        _enableRemoteServerWorkflow = [[memento objectForKey:@"enableRemoteServerWorkflow"] boolValue];

        if ([memento objectForKey:@"fullPageReloadDelay"])
            _fullPageReloadDelay = [[memento objectForKey:@"fullPageReloadDelay"] doubleValue];
        else
            _fullPageReloadDelay = 0.0;

        if ([memento objectForKey:@"eventProcessingDelay"])
            _eventProcessingDelay = [[memento objectForKey:@"eventProcessingDelay"] doubleValue];
        else
            _eventProcessingDelay = 0.0;

        _legacyPostProcessingCommand = [[memento objectForKey:@"postproc"] copy];
        if ([memento objectForKey:@"postprocEnabled"]) {
            _legacyPostProcessingEnabled = [[memento objectForKey:@"postprocEnabled"] boolValue];
        } else {
            _legacyPostProcessingEnabled = [_legacyPostProcessingCommand length] > 0;
        }

        _rubyVersionIdentifier = [[memento objectForKey:@"rubyVersion"] copy];
        if ([_rubyVersionIdentifier length] == 0)
            _rubyVersionIdentifier = @"system";

        _importGraph = [[ImportGraph alloc] init];

        NSArray *excludedPaths = [memento objectForKey:@"excludedPaths"];
        if (excludedPaths == nil)
            excludedPaths = [NSArray array];
        _excludedFolderPaths = [[NSMutableArray alloc] initWithArray:excludedPaths];

        NSArray *urlMasks = [memento objectForKey:@"urls"];
        if (urlMasks == nil)
            urlMasks = [NSArray array];
        _urlMasks = [urlMasks copy];

        _numberOfPathComponentsToUseAsName = [[memento objectForKey:@"numberOfPathComponentsToUseAsName"] integerValue];
        if (_numberOfPathComponentsToUseAsName == 0)
            _numberOfPathComponentsToUseAsName = 1;

        _customName = [memento objectForKey:@"customName"] ?: @"";

        _pendingChanges = [[NSMutableSet alloc] init];

        if ([memento objectForKey:@"postProcessingGracePeriod"])
            _postProcessingGracePeriod = [[memento objectForKey:@"postProcessingGracePeriod"] doubleValue];
        else
            _postProcessingGracePeriod = DefaultPostProcessingGracePeriod;

        if ([[memento objectForKey:@"advanced"] isKindOfClass:NSArray.class])
            _superAdvancedOptions = [memento objectForKey:@"advanced"];
        else
            _superAdvancedOptions = @[];
        [self _parseSuperAdvancedOptions];

        [self _updateAccessibility:YES];
        [self handleCompilationOptionsEnablementChanged];
        [self requestMonitoring:YES forKey:@"ui"];  // always need a folder list for UI
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setRootURL:(NSURL *)rootURL {
    if (![_rootURL isEqual:rootURL]) {
        _rootURL = rootURL;
        [self _updateValuesDerivedFromRootURL];
        [self _updateAccessibility:NO];
    }
}

- (void)_updateValuesDerivedFromRootURL {
    // we cannot monitor through symlink boundaries anyway
    [self willChangeValueForKey:@"path"];
    _path = [[_rootURL path] stringByResolvingSymlinksInPath];
    [self didChangeValueForKey:@"path"];
}

- (void)updateAccessibility {
    [self _updateAccessibility:NO];
}

- (void)_updateAccessibility:(BOOL)initially {
    BOOL wasAccessible = _accessible;

    [self willChangeValueForKey:@"accessible"];
    [self willChangeValueForKey:@"exists"];
    ATPathAccessibility acc = ATCheckPathAccessibility(_rootURL);
    if (acc == ATPathAccessibilityAccessible) {
        _accessible = YES;
        _exists = YES;
    } else if (acc == ATPathAccessibilityNotFound) {
        _accessible = NO;
        _exists = NO;
    } else if ([_rootURL startAccessingSecurityScopedResource]) {
        _accessible = YES;
        _accessingSecurityScopedResource = YES;
        _exists = YES;
    } else {
        _accessible = NO;
        _exists = YES;
    }
    [self didChangeValueForKey:@"accessible"];
    [self didChangeValueForKey:@"exists"];

    if (!initially && (!wasAccessible && _accessible)) {
        // save to create a bookmark
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }

    if (_accessible && !_monitor) {
        _monitor = [[FSMonitor alloc] initWithPath:_path];
        _monitor.delegate = self;
        _monitor.eventProcessingDelay = _eventProcessingDelay;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFilter) name:PreferencesFilterSettingsChangedNotification object:nil];
        [self updateFilter];
        [self _updateMonitoringState];
    }
}


#pragma mark -
#pragma mark Persistence

- (NSMutableDictionary *)memento {
    NSMutableDictionary *memento = [NSMutableDictionary dictionary];
    if (_lastSelectedPane)
        [memento setObject:_lastSelectedPane forKey:@"last_pane"];
    [memento setObject:[NSNumber numberWithBool:_disableLiveRefresh] forKey:@"disableLiveRefresh"];
    [memento setObject:[NSNumber numberWithBool:_enableRemoteServerWorkflow] forKey:@"enableRemoteServerWorkflow"];
    if (_fullPageReloadDelay > 0.001) {
        [memento setObject:[NSNumber numberWithDouble:_fullPageReloadDelay] forKey:@"fullPageReloadDelay"];
    }
    if (_eventProcessingDelay > 0.001) {
        [memento setObject:[NSNumber numberWithDouble:_eventProcessingDelay] forKey:@"eventProcessingDelay"];
    }
    if (fabs(_postProcessingGracePeriod - DefaultPostProcessingGracePeriod) > 0.01) {
        [memento setObject:[NSNumber numberWithDouble:_postProcessingGracePeriod] forKey:@"postProcessingGracePeriod"];
    }
    if ([_excludedFolderPaths count] > 0) {
        [memento setObject:_excludedFolderPaths forKey:@"excludedPaths"];
    }
    if ([_urlMasks count] > 0) {
        [memento setObject:_urlMasks forKey:@"urls"];
    }
    [memento setObject:_rubyVersionIdentifier forKey:@"rubyVersion"];

    [memento setObject:[NSNumber numberWithInteger:_numberOfPathComponentsToUseAsName] forKey:@"numberOfPathComponentsToUseAsName"];
    if (_customName.length > 0)
        [memento setObject:_customName forKey:@"customName"];

    if (_superAdvancedOptions.count > 0)
        [memento setObject:_superAdvancedOptions forKey:@"advanced"];

    [memento setValuesForKeysWithDictionary:_actionList.memento];

    return memento;
}


#pragma mark - Displaying

- (NSString *)displayName {
    if (_numberOfPathComponentsToUseAsName == ProjectUseCustomName)
        return _customName;
    else {
        // if there aren't as many components any more (well who knows, right?), display one
        NSString *name = [self proposedNameAtIndex:_numberOfPathComponentsToUseAsName - 1];
        if (name)
            return name;
        else
            return [self proposedNameAtIndex:0];
    }
}

- (NSString *)displayPath {
    return [_path stringByAbbreviatingWithTildeInPath];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Project(%@)", [self displayPath]];
}

- (NSComparisonResult)compareByDisplayPath:(Project *)another {
    return [self.displayPath compare:another.displayPath];
}

- (NSString *)proposedNameAtIndex:(NSInteger)index {
    NSArray *components = [self.displayPath pathComponents];
    NSInteger count = [components count];
    index = count - 1 - index;
    if (index < 0)
        return nil;
    if (index == 0 && [[components objectAtIndex:0] isEqualToString:@"~"])
        return nil;
    return [[components subarrayWithRange:NSMakeRange(index, count - index)] componentsJoinedByString:@"/"];
}


#pragma mark - Filtering

- (void)updateFilter {
    // Cannot ignore hidden files, some guys are using files like .navigation.html as
    // partials. Not sure about directories, but the usual offenders are already on
    // the excludedNames list.
    FSTreeFilter *filter = _monitor.filter;
    NSSet *excludedPaths = [NSSet setWithArray:_excludedFolderPaths];
    if (filter.ignoreHiddenFiles != NO || ![filter.enabledExtensions isEqualToSet:[Preferences sharedPreferences].allExtensions] || ![filter.excludedNames isEqualToSet:[Preferences sharedPreferences].excludedNames] || ![filter.excludedPaths isEqualToSet:excludedPaths]) {
        filter.ignoreHiddenFiles = NO;
        filter.enabledExtensions = [Preferences sharedPreferences].allExtensions;
        filter.excludedNames = [Preferences sharedPreferences].excludedNames;
        filter.excludedPaths = excludedPaths;
        [_monitor filterUpdated];
    }
}


#pragma mark -
#pragma mark File System Monitoring

- (void)ceaseAllMonitoring {
    [_monitoringRequests removeAllObjects];
    _monitor.running = NO;
}

- (void)checkBrokenPaths {
    if (_brokenPathReported)
        return;
    if (![[NSFileManager defaultManager] fileExistsAtPath:_path])
        return; // don't report spurious messages for missing folders

    NSArray *brokenPaths = [[_monitor obtainTree] brokenPaths];
    if ([brokenPaths count] > 0) {
        NSInteger result = [[NSAlert alertWithMessageText:@"Folder Cannot Be Monitored" defaultButton:@"Read More" alternateButton:@"Ignore" otherButton:nil informativeTextWithFormat:@"The following %@ cannot be monitored because of OS X FSEvents bug:\n\n\t%@\n\nMore info and workaround instructions are available on our site.", [brokenPaths count] > 0 ? @"folders" : @"folder", [[brokenPaths componentsJoinedByString:@"\n\t"] stringByReplacingOccurrencesOfString:@"_!LR_BROKEN!_" withString:@"Broken"]] runModal];
        if (result == NSAlertDefaultReturn) {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://help.livereload.com/kb/troubleshooting/os-x-fsevents-bug-may-prevent-monitoring-of-certain-folders"]];
        }
        _brokenPathReported = YES;
    }
}

- (BOOL)isFileImported:(NSString *)path {
    return [_importGraph hasReferencingPathsForPath:path];
}


- (void)requestMonitoring:(BOOL)monitoringEnabled forKey:(NSString *)key {
    if ([_monitoringRequests containsObject:key] != monitoringEnabled) {
        if (monitoringEnabled) {
//            NSLog(@"%@: requesting monitoring for %@", [self description], key);
            [_monitoringRequests addObject:key];
        } else {
//            NSLog(@"%@: unrequesting monitoring for %@", [self description], key);
            [_monitoringRequests removeObject:key];
        }

        [self _updateMonitoringState];
    }
}

- (void)_updateMonitoringState {
    BOOL shouldBeRunning = [_monitoringRequests count] > 0;
    if (_monitor && (shouldBeRunning != _monitor.running)) {
        if (shouldBeRunning) {
            NSLog(@"Activated monitoring for %@", [self displayPath]);
        } else {
            NSLog(@"Deactivated monitoring for %@", [self displayPath]);
        }
        _monitor.running = shouldBeRunning;
        if (shouldBeRunning) {
            [self rebuildImportGraph];
            [self checkBrokenPaths];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:ProjectMonitoringStateDidChangeNotification object:self];
    }
}

- (BOOL)isCompassConfigurationFile:(NSString *)relativePath {
    return MatchLastPathTwoComponents(relativePath, @"config", @"compass.rb") || MatchLastPathTwoComponents(relativePath, @".compass", @"config.rb") || MatchLastPathTwoComponents(relativePath, @"config", @"compass.config") || MatchLastPathComponent(relativePath, @"config.rb") || MatchLastPathTwoComponents(relativePath, @"src", @"config.rb");
}

- (void)scanCompassConfigurationFile:(NSString *)relativePath {
    NSString *data = [NSString stringWithContentsOfFile:[self.path stringByAppendingPathComponent:relativePath] encoding:NSUTF8StringEncoding error:nil];
    if (data) {
        if ([data isMatchedByRegex:@"compass plugins"] || [data isMatchedByRegex:@"^preferred_syntax = :(sass|scss)" options:RKLMultiline inRange:NSMakeRange(0, data.length) error:nil]) {
            _compassDetected = YES;
        }
    }
}

- (void)enqueueReloadRequestAtPath:(NSString *)relativePath {
    NSString *extension = [relativePath pathExtension];

    if (_forcedStylesheetReloadSpec && [_forcedStylesheetReloadSpec matchesPath:relativePath type:ATPathSpecEntryTypeFile]) {
        [_runningBuild addReloadRequest:@{@"path": @"force-reload-all-stylesheets.css", @"originalPath": [NSNull null]}];
    } else {
        NSString *fullPath = [_path stringByAppendingPathComponent:relativePath];
        [_runningBuild addReloadRequest:@{@"path": fullPath, @"originalPath": [NSNull null], @"localPath": fullPath}];
    }
}

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChange:(FSChange *)change {
    [_pendingChanges unionSet:change.changedFiles];

    if (!(_runningPostProcessor || (_lastPostProcessingRunDate > 0 && [NSDate timeIntervalSinceReferenceDate] < _lastPostProcessingRunDate + _postProcessingGracePeriod))) {
        _pendingPostProcessing = YES;
    }

    [self processPendingChanges];

    if (change.folderListChanged) {
        [self willChangeValueForKey:@"filterOptions"];
        [self didChangeValueForKey:@"filterOptions"];
    }
}

- (NSArray *)rootPathsForPaths:(id<NSFastEnumeration>)paths {
    NSMutableSet *result = [NSMutableSet new];
    for (NSString *path in paths) {
        NSSet *rootPaths = [_importGraph rootReferencingPathsForPath:path];
        if (rootPaths.count > 0)
            [result addObjectsFromArray:rootPaths.allObjects];
        else
            [result addObject:path];
    }
    return [result.allObjects copy];
}

- (void)processBatchOfPendingChanges:(NSSet *)pathes {
    BOOL invokePostProcessor = _pendingPostProcessing;
    _pendingPostProcessing = NO;

    ++_buildsRunning;

    switch (pathes.count) {
        case 0:  break;
        case 1:  console_printf("Changed: %s", [[pathes anyObject] UTF8String]); break;
        default: console_printf("Changed: %s and %d others", [[pathes anyObject] UTF8String], (int)pathes.count - 1); break;
    }

    [self updateImportGraphForPaths:pathes];

    NSArray *actions = [self.actionList.activeActions copy];

    [self invokeFileActions:actions forModifiedPaths:pathes withCompletionBlock:^{
        // TODO: not clear why postprocessing is bound to existence of reload requests
        // (IMO it's a cheap way to ignore changes that are expected to produce another change later)
        if ([_runningBuild hasReloadRequests]) {
            if (invokePostProcessor) {
                [self invokePostProcessingActions:actions forModifiedPaths:pathes withCompletionBlock:^{
                    //
                }];
            } else {
                console_printf("Skipping post-processing.");
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidDetectChangeNotification object:self];
            StatIncrement(BrowserRefreshCountStat, 1);
        }

        --_buildsRunning;
        [self checkIfBuildFinished];

//        S_app_handle_change(json_object_2("root", json_nsstring(_path), "paths", nodeapp_objc_to_json([pathes allObjects])));
    }];
}

- (void)startBuild {
    if (!_buildInProgress) {
        _buildInProgress = YES;
        _runningBuild = [[LRBuildResult alloc] initWithProject:self];
        NSLog(@"Build starting...");
    }
}

- (void)checkIfBuildFinished {
    if (_buildInProgress && !(_buildsRunning > 0 || _processingChanges)) {
        _buildInProgress = NO;
        [_runningBuild sendReloadRequests];
        _lastFinishedBuild = _runningBuild;
        _runningBuild = nil;
        NSLog(@"Build finished.");
        [self postNotificationName:ProjectBuildFinishedNotification];
    }
}

- (void)displayResult:(LROperationResult *)result key:(NSString *)key {
    if (result.failed) {
        NSLog(@"Compilation error in %@:\n%@", key, result.rawOutput);
        LRMessage *error = [result.errors firstObject];
        if (error) {
            ToolOutput *output = [[ToolOutput alloc] initWithCompiler:nil type:ToolOutputTypeError sourcePath:error.filePath line:error.line message:error.text output:result.rawOutput];
            output.project = self;
            [[[ToolOutputWindowController alloc] initWithCompilerOutput:output key:key] show];
        }
    } else {
        [ToolOutputWindowController hideOutputWindowWithKey:key];
    }
}

- (void)invokeFileActions:(NSArray *)allActions forModifiedPaths:(NSSet *)paths withCompletionBlock:(dispatch_block_t)completionBlock {
    NSMutableArray *fileTargets = [NSMutableArray new];
    for (Action *action in allActions) {
        [fileTargets addObjectsFromArray:[action fileTargetsForModifiedFiles:paths]];
    }

    [self invokeTargers:fileTargets withCompletionBlock:completionBlock];
}

- (void)invokePostProcessingActions:(NSArray *)allActions forModifiedPaths:(NSSet *)paths withCompletionBlock:(dispatch_block_t)completionBlock {
    NSArray *targets = [allActions arrayByMappingElementsUsingBlock:^id(Action *action) {
        return [action targetForModifiedFiles:paths];
    }];

    if (targets.count > 0) {
        _runningPostProcessor = YES;
        [self invokeTargers:targets withCompletionBlock:^{
            _runningPostProcessor = NO;
            _lastPostProcessingRunDate = [NSDate timeIntervalSinceReferenceDate];
            completionBlock();
        }];
    } else {
        completionBlock();
    }
}

- (void)invokeTargers:(NSArray *)targets withCompletionBlock:(dispatch_block_t)completionBlock {
    [targets p2_enumerateObjectsAsynchronouslyUsingBlock:^(LRTargetResult *target, NSUInteger idx, BOOL *stop, dispatch_block_t callback) {
        [target invokeWithCompletionBlock:callback];
    } completionBlock:completionBlock];
}

- (void)processPendingChanges {
    if (_processingChanges)
        return;

    [self startBuild];
    _processingChanges = YES;

    while (_pendingChanges.count > 0 || _pendingPostProcessing) {
        NSSet *paths = _pendingChanges;
        _pendingChanges = [[NSMutableSet alloc] init];
        [self processBatchOfPendingChanges:paths];
    }

    _processingChanges = NO;
    [self checkIfBuildFinished];
}

- (FSTree *)tree {
    return _monitor.tree;
}

- (FSTree *)obtainTree {
    return [_monitor obtainTree];
}

- (void)rescanTree {
    [_monitor rescan];
}


#pragma mark - Options

- (void)setCustomName:(NSString *)customName {
    if (_customName != customName) {
        _customName = customName;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setNumberOfPathComponentsToUseAsName:(NSInteger)numberOfPathComponentsToUseAsName {
    if (_numberOfPathComponentsToUseAsName != numberOfPathComponentsToUseAsName) {
        _numberOfPathComponentsToUseAsName = numberOfPathComponentsToUseAsName;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (id)enumerateParentFoldersFromFolder:(NSString *)folder with:(id(^)(NSString *folder, NSString *relativePath, BOOL *stop))block {
    BOOL stop = NO;
    NSString *relativePath = @"";
    id result;
    if ((result = block(folder, relativePath, &stop)) != nil)
        return result;
    while (!stop && [[folder pathComponents] count] > 1) {
        relativePath = [[folder lastPathComponent] stringByAppendingPathComponent:relativePath];
        folder = [folder stringByDeletingLastPathComponent];
        if ((result = block(folder, relativePath, &stop)) != nil)
            return result;
    }
    return nil;
}

- (void)handleCompilationOptionsEnablementChanged {
    // TODO: update for the new actions system
    [self requestMonitoring:NO forKey:CompilersEnabledMonitoringKey];
}

- (void)setDisableLiveRefresh:(BOOL)disableLiveRefresh {
    if (_disableLiveRefresh != disableLiveRefresh) {
        _disableLiveRefresh = disableLiveRefresh;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setEnableRemoteServerWorkflow:(BOOL)enableRemoteServerWorkflow {
    if (_enableRemoteServerWorkflow != enableRemoteServerWorkflow) {
        _enableRemoteServerWorkflow = enableRemoteServerWorkflow;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setFullPageReloadDelay:(NSTimeInterval)fullPageReloadDelay {
    if (fneq(_fullPageReloadDelay, fullPageReloadDelay, TIME_EPS)) {
        _fullPageReloadDelay = fullPageReloadDelay;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setEventProcessingDelay:(NSTimeInterval)eventProcessingDelay {
    if (fneq(_eventProcessingDelay, eventProcessingDelay, TIME_EPS)) {
        _eventProcessingDelay = eventProcessingDelay;
        _monitor.eventProcessingDelay = _eventProcessingDelay;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setPostProcessingGracePeriod:(NSTimeInterval)postProcessingGracePeriod {
    if (flt(postProcessingGracePeriod, 0.01, TIME_EPS))
        return;
    if (fneq(_postProcessingGracePeriod, postProcessingGracePeriod, TIME_EPS)) {
        _postProcessingGracePeriod = postProcessingGracePeriod;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setRubyVersionIdentifier:(NSString *)rubyVersionIdentifier {
    if (_rubyVersionIdentifier != rubyVersionIdentifier) {
        _rubyVersionIdentifier = [rubyVersionIdentifier copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}


#pragma mark - Paths

- (NSString *)pathForRelativePath:(NSString *)relativePath {
    return [[_path stringByExpandingTildeInPath] stringByAppendingPathComponent:relativePath];
}

- (BOOL)isPathInsideProject:(NSString *)path {
    NSString *root = [_path stringByResolvingSymlinksInPath];
    path = [path stringByResolvingSymlinksInPath];

    NSArray *rootComponents = [root pathComponents];
    NSArray *pathComponents = [path pathComponents];

    NSInteger pathCount = [pathComponents count];
    NSInteger rootCount = [rootComponents count];

    NSInteger numberOfIdenticalComponents = 0;
    while (numberOfIdenticalComponents < MIN(pathCount, rootCount) && [[rootComponents objectAtIndex:numberOfIdenticalComponents] isEqualToString:[pathComponents objectAtIndex:numberOfIdenticalComponents]])
        ++numberOfIdenticalComponents;

    return (numberOfIdenticalComponents == rootCount);
}

- (NSString *)relativePathForPath:(NSString *)path {
    NSString *root = [_path stringByResolvingSymlinksInPath];
    path = [path stringByResolvingSymlinksInPath];

    if ([root isEqualToString:path]) {
        return @"";
    }

    NSArray *rootComponents = [root pathComponents];
    NSArray *pathComponents = [path pathComponents];

    NSInteger pathCount = [pathComponents count];
    NSInteger rootCount = [rootComponents count];

    NSInteger numberOfIdenticalComponents = 0;
    while (numberOfIdenticalComponents < MIN(pathCount, rootCount) && [[rootComponents objectAtIndex:numberOfIdenticalComponents] isEqualToString:[pathComponents objectAtIndex:numberOfIdenticalComponents]])
        ++numberOfIdenticalComponents;

    NSInteger numberOfDotDotComponents = (rootCount - numberOfIdenticalComponents);
    NSInteger numberOfTrailingComponents = (pathCount - numberOfIdenticalComponents);
    NSMutableArray *components = [NSMutableArray arrayWithCapacity:numberOfDotDotComponents + numberOfTrailingComponents];
    for (NSInteger i = 0; i < numberOfDotDotComponents; ++i)
        [components addObject:@".."];
    [components addObjectsFromArray:[pathComponents subarrayWithRange:NSMakeRange(numberOfIdenticalComponents, numberOfTrailingComponents)]];

    return [components componentsJoinedByString:@"/"];
}

- (NSString *)safeDisplayPath {
    NSString *src = [self displayPath];
    return [src stringByReplacingOccurrencesOfRegex:@"\\w" usingBlock:^NSString *(NSInteger captureCount, NSString *const __unsafe_unretained *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        unichar ch = 'a' + (rand() % ('z' - 'a' + 1));
        return [NSString stringWithCharacters:&ch length:1];
    }];
}


#pragma mark - Import Support

- (void)updateImportGraphForPath:(NSString *)relativePath compiler:(Compiler *)compiler {
    NSSet *referencedPathFragments = [compiler referencedPathFragmentsForPath:[_path stringByAppendingPathComponent:relativePath]];

    NSMutableSet *referencedPaths = [NSMutableSet set];
    for (NSString *pathFragment in referencedPathFragments) {
        if ([pathFragment rangeOfString:@"compass"].location == 0 || [pathFragment rangeOfString:@"ZURB-foundation"].location != NSNotFound) {
            _compassDetected = YES;
        }

        NSString *path = [_monitor.tree pathOfBestFileMatchingPathSuffix:pathFragment preferringSubtree:[relativePath stringByDeletingLastPathComponent]];
        if (path) {
            [referencedPaths addObject:path];
        }
    }

    [_importGraph setRereferencedPaths:referencedPaths forPath:relativePath];
}

- (void)updateImportGraphForPath:(NSString *)relativePath {
    NSString *fullPath = [_path stringByAppendingPathComponent:relativePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        [_importGraph removePath:relativePath collectingPathsToRecomputeInto:nil];
        return;
    }

    if ([self isCompassConfigurationFile:relativePath]) {
        [self scanCompassConfigurationFile:relativePath];
    }

    NSString *extension = [relativePath pathExtension];

    for (Compiler *compiler in [PluginManager sharedPluginManager].compilers) {
        if ([compiler.extensions containsObject:extension]) {
            // TODO: move import graph handling into actions
            [self updateImportGraphForPath:relativePath compiler:compiler];
            return;
        }
    }
}

- (void)updateImportGraphForPaths:(NSSet *)paths {
    for (NSString *path in paths) {
        [self updateImportGraphForPath:path];
    }
    NSLog(@"Incremental import graph update finished. %@", _importGraph);
}

- (void)rebuildImportGraph {
    _compassDetected = NO;
    [_importGraph removeAllPaths];
    NSArray *paths = [_monitor.tree pathsOfFilesMatching:^BOOL(NSString *name) {
        NSString *extension = [name pathExtension];

        // a hack for Compass
        if ([extension isEqualToString:@"rb"] || [extension isEqualToString:@"config"]) {
            return YES;
        }

        // TODO: only analyze files for enabled compilers
        for (Compiler *compiler in [PluginManager sharedPluginManager].compilers) {
            if ([compiler.extensions containsObject:extension]) {
                return YES;
            }
        }

        return NO;
    }];
    for (NSString *path in paths) {
        [self updateImportGraphForPath:path];
    }
    NSLog(@"Full import graph rebuild finished. %@", _importGraph);
}


#pragma mark - Excluded paths

- (NSArray *)excludedPaths {
    return _excludedFolderPaths;
}

- (void)addExcludedPath:(NSString *)path {
    if (![_excludedFolderPaths containsObject:path]) {
        [self willChangeValueForKey:@"excludedPaths"];
        [_excludedFolderPaths addObject:path];
        [self didChangeValueForKey:@"excludedPaths"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
        [self updateFilter];
    }
}

- (void)removeExcludedPath:(NSString *)path {
    if ([_excludedFolderPaths containsObject:path]) {
        [self willChangeValueForKey:@"excludedPaths"];
        [_excludedFolderPaths removeObject:path];
        [self didChangeValueForKey:@"excludedPaths"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
        [self updateFilter];
    }
}


#pragma mark - URLs

- (void)setUrlMasks:(NSArray *)urlMasks {
    if (_urlMasks != urlMasks) {
        _urlMasks = [urlMasks copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (NSString *)formattedUrlMaskList {
    return [_urlMasks componentsJoinedByString:@", "];
}

- (void)setFormattedUrlMaskList:(NSString *)formattedUrlMaskList {
    self.urlMasks = [formattedUrlMaskList componentsSeparatedByRegex:@"\\s*,\\s*|\\s+"];
}


#pragma mark - Path Options

- (NSArray *)pathOptions {
    NSMutableArray *pathOptions = [NSMutableArray new];
    for (NSString *path in self.tree.folderPaths) {
        [pathOptions addObject:[FilterOption filterOptionWithSubfolder:path]];
    }
    return pathOptions;
}

- (NSArray *)availableSubfolders {
    return self.tree.folderPaths;
}


#pragma mark - Filtering loop prevention hack

- (BOOL)hackhack_shouldFilterFile:(LRProjectFile *)file {
    NSDate *date = _fileDatesHack[file.relativePath];
    if (date) {
        NSDate *fileDate = nil;
        BOOL ok = [file.absoluteURL getResourceValue:&fileDate forKey:NSURLContentModificationDateKey error:NULL];
        if (ok && [fileDate compare:date] != NSOrderedDescending) {
            // file modification time is not later than the filtering time
            NSLog(@"NOT applying filter to %@/%@ to avoid an infinite loop", _path, file.relativePath);
            return NO;
        }
    }
    return YES;
}

- (void)hackhack_didFilterFile:(LRProjectFile *)file {
    _fileDatesHack[file.relativePath] = [NSDate date];
}

- (void)hackhack_didWriteCompiledFile:(LRProjectFile *)file {
    [_fileDatesHack removeObjectForKey:file.relativePath];
}


#pragma mark - Rebuilding

- (void)rebuildAll {
    [_pendingChanges unionSet:[NSSet setWithArray:self.tree.filePaths]];
    _pendingPostProcessing = YES;
    [self processPendingChanges];
}


#pragma mark - Analysis

- (void)setAnalysisInProgress:(BOOL)analysisInProgress forTask:(id)task {
    if (analysisInProgress == [_runningAnalysisTasks containsObject:task])
        return;

    if (analysisInProgress) {
        [_runningAnalysisTasks addObject:task];
        NSLog(@"Analysis started (%d): %@", (int)_runningAnalysisTasks.count, task);
    } else {
        [_runningAnalysisTasks removeObject:task];
        NSLog(@"Analysis finished (%d): %@", (int)_runningAnalysisTasks.count, task);
    }

    BOOL inProgress = (_runningAnalysisTasks.count > 0);
    if (inProgress && !_analysisInProgress) {
        _analysisInProgress = YES;
    } else if (!inProgress && _analysisInProgress) {
        // delay b/c maybe some other task is going to start very soon
        dispatch_async(dispatch_get_main_queue(), ^{
            if ((_runningAnalysisTasks.count == 0) && _analysisInProgress) {
                NSLog(@"Analysis finished notification.");
                _analysisInProgress = NO;
                [self postNotificationName:ProjectAnalysisDidFinishNotification];
            }
        });
    }
}


#pragma mark - Super-advanced options

- (void)_parseSuperAdvancedOptions {
    _quuxMode = NO;
    _forcedStylesheetReloadSpec = nil;

    NSMutableArray *messages = [NSMutableArray new];

    NSArray *items = _superAdvancedOptions;
    NSUInteger count = items.count;
    for (NSUInteger i = 0; i < count; ++i) {
        NSString *option = items[i];
        if ([option isEqualToString:@"quux"]) {
            _quuxMode = YES;
            [messages addObject:@"✓ quux on"];
        } else if ([option isEqualToString:@"reload-all-stylesheets-for"]) {
            if (++i == count) {
                [messages addObject:[NSString stringWithFormat:@"%@ requires an argument", option]];
            } else {
                NSString *value = items[i];
                NSError *__autoreleasing error;
                _forcedStylesheetReloadSpec = [ATPathSpec pathSpecWithString:value syntaxOptions:ATPathSpecSyntaxFlavorExtended error:&error];
                if (!_forcedStylesheetReloadSpec) {
                    [messages addObject:[NSString stringWithFormat:@"%@ parse error: %@", option, error.localizedDescription]];
                } else {
                    [messages addObject:[NSString stringWithFormat:@"✓ %@ = %@", option, _forcedStylesheetReloadSpec.description]];
                }
            }
        } else {
            [messages addObject:[NSString stringWithFormat:@"unknown: %@", option]];
        }
    }

    if (messages.count == 0) {
        [messages addObject:@"No super-advanced options set. Email support to get some? :-)"];
    }

    _superAdvancedOptionsFeedback = [messages copy];
}

- (void)setSuperAdvancedOptions:(NSArray *)superAdvancedOptions {
    if (_superAdvancedOptions != superAdvancedOptions && ![_superAdvancedOptions isEqual:superAdvancedOptions]) {
        _superAdvancedOptions = [superAdvancedOptions copy];
        [self _parseSuperAdvancedOptions];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (NSString *)superAdvancedOptionsString {
    return [_superAdvancedOptions quotedArgumentStringUsingBourneQuotingStyle];
}

- (void)setSuperAdvancedOptionsString:(NSString *)superAdvancedOptionsString {
    [self setSuperAdvancedOptions:[superAdvancedOptionsString argumentsArrayUsingBourneQuotingStyle]];
}

- (NSString *)superAdvancedOptionsFeedbackString {
    return [_superAdvancedOptionsFeedback componentsJoinedByString:@" • "];
}

@end
