using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Twins;

namespace LiveReload.Model {
    public class Project : ModelBase {

        private string path;

        //FSMonitor* _monitor;

        //private bool clientsConnected;
        private bool enabled;

        private HashSet<Object> monitoringRequests;

        private string lastSelectedPane;
        //private bool dirty;

        private string postProcessingCommand;
        private string postProcessingScriptName;
        private bool postProcessingEnabled;
        //TimeSpan postProcessingGracePeriod;

        private string rubyVersionIdentifier;

        //NSMutableDictionary* _compilerOptions;
        private bool compilationEnabled;

        //ImportGraph* _importGraph;
        //private bool compassDetected;

        private bool disableLiveRefresh;
        private bool enableRemoteServerWorkflow;
        //private TimeSpan fullPageReloadDelay;
        //private TimeSpan eventProcessingDelay;

        //private bool brokenPathReported;

        //NSMutableArray* _excludedFolderPaths;

        int numberOfPathComponentsToUseAsName;
        private string customName;

        //NSArray* _urlMasks;

        private HashSet<Object> pendingChanges;
        //private bool processingChanges;

        //private bool runningPostProcessor;
        //private bool pendingPostProcessing;
        //private TimeSpan lastPostProcessingRunDate;


        public Project() {
            path = "";
            enabled = true;
            customName = "";
        }

        public Project(string path) { // LOL
            this.path = path;
            enabled = true;
            customName = "";
        }

        public Project(string path, Dictionary<string, Object> memento) {
            // we cannot monitor through symlink boundaries anyway
            //        _path = [[path stringByResolvingSymlinksInPath] copy];

            customName = "";

            enabled = true;

            //    _monitor = [[FSMonitor alloc] initWithPath:_path];
            //    _monitor.delegate = self;
            //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFilter) name:PreferencesFilterSettingsChangedNotification object:nil];
            //this.updateFilter;

            //    _compilerOptions = [[NSMutableDictionary alloc] init];
            monitoringRequests = new HashSet<Object>();

            lastSelectedPane = (string)memento["last_pane"];

            //    id raw = [memento objectForKey:@"compilers"];
            //    if (raw) {
            //        PluginManager *pluginManager = [PluginManager sharedPluginManager];
            //        [raw enumerateKeysAndObjectsUsingBlock:^(id uniqueId, id compilerMemento, BOOL *stop) {
            //            Compiler *compiler = [pluginManager compilerWithUniqueId:uniqueId];
            //            if (compiler) {
            //                [_compilerOptions setObject:[[[CompilationOptions alloc] initWithCompiler:compiler memento:compilerMemento] autorelease] forKey:uniqueId];
            //            } else {
            //                // TODO: save data for unknown compilers and re-add them when creating a memento
            //            }
            //        }];
            //    }

            if (memento.ContainsKey("compilationEnabled")) {
                compilationEnabled = (bool)memento["compilationEnabled"];
            }
            else {
                compilationEnabled = false;
                //        [[memento objectForKey:@"compilers"] enumerateKeysAndObjectsUsingBlock:^(id uniqueId, id compilerMemento, BOOL *stop) {
                //            if ([[compilerMemento objectForKey:@"mode"] isEqualToString:@"compile"]) {
                //                _compilationEnabled = YES;
                //            }
                //        }];
            }

            disableLiveRefresh = (bool)memento["disableLiveRefresh"];
            enableRemoteServerWorkflow = (bool)memento["enableRemoteServerWorkflow"];

            //    if ([memento objectForKey:@"fullPageReloadDelay"])
            //        _fullPageReloadDelay = [[memento objectForKey:@"fullPageReloadDelay"] doubleValue];
            //    else
            //        _fullPageReloadDelay = 0.0;

            //if (memento.ContainsKey("eventProcessingDelay"))
            //    eventProcessingDelay = (TimeSpan) memento["eventProcessingDelay"];
            //else
            //    eventProcessingDelay = new TimeSpan(0.0);
            //_monitor.eventProcessingDelay = _eventProcessingDelay;

            postProcessingCommand = (string)memento["postproc"];
            postProcessingScriptName = (string)memento["postprocScript"];
            if (memento.ContainsKey("postprocEnabled")) {
                postProcessingEnabled = (bool)memento["postprocEnabled"];
            }
            else {
                postProcessingEnabled = (postProcessingScriptName.Length > 0) || (postProcessingCommand.Length > 0);
            }

            rubyVersionIdentifier = (string)memento["rubyVersion"];
            if (rubyVersionIdentifier.Length == 0)
                rubyVersionIdentifier = "system";

            //    _importGraph = [[ImportGraph alloc] init];

            //    NSArray *excludedPaths = [memento objectForKey:@"excludedPaths"];
            //    if (excludedPaths == nil)
            //        excludedPaths = [NSArray array];
            //    _excludedFolderPaths = [[NSMutableArray alloc] initWithArray:excludedPaths];

            //    NSArray *urlMasks = [memento objectForKey:@"urls"];
            //    if (urlMasks == nil)
            //        urlMasks = [NSArray array];
            //    _urlMasks = [urlMasks copy];

            numberOfPathComponentsToUseAsName = (int)memento["numberOfPathComponentsToUseAsName"];
            if (numberOfPathComponentsToUseAsName == 0)
                numberOfPathComponentsToUseAsName = 1;

            //    _customName = [memento objectForKey:@"customName"] ?: @"";


            pendingChanges = new HashSet<Object>();

            //if (memento.ContainsKey("postProcessingGracePeriod"))
            //    postProcessingGracePeriod = new TimeSpan( (double) memento["postProcessingGracePeriod"]));
            //else
            //    postProcessingGracePeriod = DefaultPostProcessingGracePeriod;

            //this.handleCompilationOptionsEnablementChanged;
        }


    }
}


/*

#define PathKey @"path"

#define DefaultPostProcessingGracePeriod 0.5

NSString *ProjectDidDetectChangeNotification = @"ProjectDidDetectChangeNotification";
NSString *ProjectWillBeginCompilationNotification = @"ProjectWillBeginCompilationNotification";
NSString *ProjectDidEndCompilationNotification = @"ProjectDidEndCompilationNotification";
NSString *ProjectMonitoringStateDidChangeNotification = @"ProjectMonitoringStateDidChangeNotification";
NSString *ProjectNeedsSavingNotification = @"ProjectNeedsSavingNotification";
EVENTBUS_DEFINE_EVENT(project_fs_change_event);

static NSString *CompilersEnabledMonitoringKey = @"someCompilersEnabled";

void C_projects__notify_changed(json_t *arg) {
    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidDetectChangeNotification object:nil];
    eventbus_post(project_fs_change_event, NULL);
}

void C_projects__notify_compilation_started(json_t *arg) {
    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectWillBeginCompilationNotification object:nil];
}

void C_projects__notify_compilation_finished(json_t *arg) {
    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidEndCompilationNotification object:nil];
}



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


@implementation Project

@synthesize path=_path;
@synthesize dirty=_dirty;
@synthesize lastSelectedPane=_lastSelectedPane;
@synthesize enabled=_enabled;
@synthesize compilationEnabled=_compilationEnabled;
@synthesize postProcessingCommand=_postProcessingCommand;
@synthesize postProcessingScriptName=_postProcessingScriptName;
@synthesize postProcessingEnabled=_postProcessingEnabled;
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



- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_path release], _path = nil;
    [_monitor release], _monitor = nil;
    [_compilerOptions release], _compilerOptions = nil;
    [_monitoringRequests release], _monitoringRequests = nil;
    [_postProcessingCommand release], _postProcessingCommand = nil;
    [_importGraph release], _importGraph = nil;
    [_rubyVersionIdentifier release], _rubyVersionIdentifier = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Persistence

- (NSMutableDictionary *)memento {
    NSMutableDictionary *memento = [NSMutableDictionary dictionary];
    [memento setObject:[_compilerOptions dictionaryByMappingValuesToSelector:@selector(memento)] forKey:@"compilers"];
    if (_lastSelectedPane)
        [memento setObject:_lastSelectedPane forKey:@"last_pane"];
    if ([_postProcessingCommand length] > 0) {
        [memento setObject:_postProcessingCommand forKey:@"postproc"];
    }
    if ([_postProcessingScriptName length] > 0) {
        [memento setObject:_postProcessingScriptName forKey:@"postprocScript"];
        [memento setObject:[NSNumber numberWithBool:_postProcessingEnabled] forKey:@"postprocEnabled"];
    }
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
    [memento setObject:[NSNumber numberWithBool:_compilationEnabled ] forKey:@"compilationEnabled"];

    [memento setObject:[NSNumber numberWithInteger:_numberOfPathComponentsToUseAsName] forKey:@"numberOfPathComponentsToUseAsName"];
    if (_customName.length > 0)
        [memento setObject:_customName forKey:@"customName"];

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

        BOOL shouldBeRunning = [_monitoringRequests count] > 0;
        if (shouldBeRunning != _monitor.running) {
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
}

- (void)compile:(NSString *)relativePath under:(NSString *)rootPath with:(Compiler *)compiler options:(CompilationOptions *)compilationOptions {
    NSString *path = [rootPath stringByAppendingPathComponent:relativePath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        return; // don't try to compile deleted files
    FileCompilationOptions *fileOptions = [self optionsForFileAtPath:relativePath in:compilationOptions];
    if (fileOptions.destinationDirectory != nil || !compiler.needsOutputDirectory) {
        NSString *derivedName = fileOptions.destinationName;
        NSString *derivedPath = (compiler.needsOutputDirectory ? [fileOptions.destinationDirectory stringByAppendingPathComponent:derivedName] : [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:derivedName]);

        ToolOutput *compilerOutput = nil;
        [compiler compile:relativePath into:derivedPath under:rootPath inProject:self with:compilationOptions compilerOutput:&compilerOutput];
        if (compilerOutput) {
            compilerOutput.project = self;

            [[[[ToolOutputWindowController alloc] initWithCompilerOutput:compilerOutput key:path] autorelease] show];
        } else {
            [ToolOutputWindowController hideOutputWindowWithKey:path];
        }
    } else {
        NSLog(@"Ignoring %@ because destination directory is not set.", relativePath);
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

- (void)processChangeAtPath:(NSString *)relativePath reloadRequests:(json_t *)reloadRequests {
    NSString *extension = [relativePath pathExtension];

    BOOL compilerFound = NO;
    for (Compiler *compiler in [PluginManager sharedPluginManager].compilers) {
        if (_compassDetected && [compiler.uniqueId isEqualToString:@"sass"])
            continue;
        else if (!_compassDetected && [compiler.uniqueId isEqualToString:@"compass"])
            continue;
        if ([compiler.extensions containsObject:extension]) {
            compilerFound = YES;
            CompilationOptions *compilationOptions = [self optionsForCompiler:compiler create:YES];
            if (_compilationEnabled && compilationOptions.active) {
                [[NSNotificationCenter defaultCenter] postNotificationName:ProjectWillBeginCompilationNotification object:self];
                [self compile:relativePath under:_path with:compiler options:compilationOptions];
                [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidEndCompilationNotification object:self];
                StatGroupIncrement(CompilerChangeCountStatGroup, compiler.uniqueId, 1);
                StatGroupIncrement(CompilerChangeCountEnabledStatGroup, compiler.uniqueId, 1);
                break;
            } else {
                FileCompilationOptions *fileOptions = [self optionsForFileAtPath:relativePath in:compilationOptions];
                NSString *derivedName = fileOptions.destinationName;
                NSString *originalPath = [_path stringByAppendingPathComponent:relativePath];
                json_array_append_new(reloadRequests, json_object_2("path", json_nsstring(derivedName), "originalPath", json_nsstring(originalPath)));
                NSLog(@"Broadcasting a fake change in %@ instead of %@ (compiler %@).", derivedName, relativePath, compiler.name);
                StatGroupIncrement(CompilerChangeCountStatGroup, compiler.uniqueId, 1);
                break;
//            } else if (compilationOptions.mode == CompilationModeDisabled) {
//                compilerFound = NO;
            }
        }
    }

    if (!compilerFound) {
        json_array_append_new(reloadRequests, json_object_2("path", json_nsstring([_path stringByAppendingPathComponent:relativePath]), "originalPath", json_null()));
    }
}

// I don't think this will ever be needed, but not throwing the code away yet
#ifdef AUTORESCAN_WORKAROUND_ENABLED
- (void)rescanRecentlyChangedPaths {
    NSLog(@"Rescanning %@ again in case some compiler was slow to write the changes.", _path);
    [_monitor rescan];
}
#endif

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChangeAtPathes:(NSSet *)paths {
    [_pendingChanges unionSet:paths];

    if (!(_runningPostProcessor || (_lastPostProcessingRunDate > 0 && [NSDate timeIntervalSinceReferenceDate] < _lastPostProcessingRunDate + _postProcessingGracePeriod))) {
        _pendingPostProcessing = YES;
    }

    [self processPendingChanges];
}

- (void)processBatchOfPendingChanges:(NSSet *)pathes {
    BOOL invokePostProcessor = _pendingPostProcessing;
    _pendingPostProcessing = NO;

    switch (pathes.count) {
        case 0:  break;
        case 1:  console_printf("Changed: %s", [[pathes anyObject] UTF8String]); break;
        default: console_printf("Changed: %s and %d others", [[pathes anyObject] UTF8String], pathes.count - 1); break;
    }

    [self updateImportGraphForPaths:pathes];

    json_t *reloadRequests = json_array();

#ifdef AUTORESCAN_WORKAROUND_ENABLED
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(rescanRecentlyChangedPaths) object:nil];
    [self performSelector:@selector(rescanRecentlyChangedPaths) withObject:nil afterDelay:1.0];
#endif

    for (NSString *relativePath in pathes) {
        NSSet *realPaths = [_importGraph rootReferencingPathsForPath:relativePath];
        if ([realPaths count] > 0) {
            NSLog(@"Instead of imported file %@, processing changes in %@", relativePath, [[realPaths allObjects] componentsJoinedByString:@", "]);
            for (NSString *path in realPaths) {
                [self processChangeAtPath:path reloadRequests:reloadRequests];
            }
        } else {
            [self processChangeAtPath:relativePath reloadRequests:reloadRequests];
        }

    }

    if (json_array_size(reloadRequests) > 0) {
        if (_postProcessingScriptName.length > 0 && _postProcessingEnabled) {
            UserScript *userScript = self.postProcessingScript;
            if (invokePostProcessor && userScript.exists) {
                ToolOutput *toolOutput = nil;

                _runningPostProcessor = YES;
                [userScript invokeForProjectAtPath:_path withModifiedFiles:pathes completionHandler:^(BOOL invoked, ToolOutput *output, NSError *error) {
                    _runningPostProcessor = NO;
                    _lastPostProcessingRunDate = [NSDate timeIntervalSinceReferenceDate];

                    if (toolOutput) {
                        toolOutput.project = self;
                        [[[[ToolOutputWindowController alloc] initWithCompilerOutput:toolOutput key:[NSString stringWithFormat:@"%@.postproc", _path]] autorelease] show];
                    }
                }];
            } else {
                console_printf("Skipping post-processing.");
            }
        }

        json_t *arg = json_object_3("changes", reloadRequests, "forceFullReload", json_bool(self.disableLiveRefresh), "fullReloadDelay", json_real(_fullPageReloadDelay));
        S_reloader_reload(arg);

        [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidDetectChangeNotification object:self];
        eventbus_post(project_fs_change_event, NULL);
        StatIncrement(BrowserRefreshCountStat, 1);
    } else {
        json_decref(reloadRequests);
    }

    S_app_handle_change(json_object_2("root", json_nsstring(_path), "paths", nodeapp_objc_to_json([pathes allObjects])));
}

- (void)processPendingChanges {
    if (_processingChanges)
        return;

    _processingChanges = YES;

    while (_pendingChanges.count > 0 || _pendingPostProcessing) {
        NSSet *paths = [_pendingChanges autorelease];
        _pendingChanges = [[NSMutableSet alloc] init];
        [self processBatchOfPendingChanges:paths];
    }

    _processingChanges = NO;
}

- (FSTree *)tree {
    return _monitor.tree;
}

- (FSTree *)obtainTree {
    return [_monitor obtainTree];
}


#pragma mark - Compilation

- (NSArray *)compilersInUse {
    FSTree *tree = [_monitor obtainTree];
    return [[PluginManager sharedPluginManager].compilers filteredArrayUsingBlock:^BOOL(id value) {
        Compiler *compiler = value;
        if (_compassDetected && [compiler.uniqueId isEqualToString:@"sass"])
            return NO;
        else if (!_compassDetected && [compiler.uniqueId isEqualToString:@"compass"])
            return NO;
        return [compiler pathsOfSourceFilesInTree:tree].count > 0;
    }];
}


#pragma mark - Options

- (void)setCustomName:(NSString *)customName {
    if (_customName != customName) {
        [_customName autorelease];
        _customName = [customName retain];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setNumberOfPathComponentsToUseAsName:(NSInteger)numberOfPathComponentsToUseAsName {
    if (_numberOfPathComponentsToUseAsName != numberOfPathComponentsToUseAsName) {
        _numberOfPathComponentsToUseAsName = numberOfPathComponentsToUseAsName;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (CompilationOptions *)optionsForCompiler:(Compiler *)compiler create:(BOOL)create {
    NSString *uniqueId = compiler.uniqueId;
    CompilationOptions *options = [_compilerOptions objectForKey:uniqueId];
    if (options == nil && create) {
        options = [[[CompilationOptions alloc] initWithCompiler:compiler memento:nil] autorelease];
        [_compilerOptions setObject:options forKey:uniqueId];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
    return options;
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

- (FileCompilationOptions *)optionsForFileAtPath:(NSString *)sourcePath in:(CompilationOptions *)compilationOptions {
    FileCompilationOptions *fileOptions = [compilationOptions optionsForFileAtPath:sourcePath create:YES];

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    FSTree *tree = self.tree;
    if (fileOptions.destinationNameMask.length == 0) {
        // for a name like foo.php.jade, check if foo.php already exists in the project
        NSString *bareName = [[sourcePath lastPathComponent] stringByDeletingPathExtension];
        if ([bareName pathExtension].length > 0 && tree && [tree containsFileNamed:bareName]) {
            fileOptions.destinationName = bareName;
        } else {
            fileOptions.destinationNameMask = [NSString stringWithFormat:@"*.%@", compilationOptions.compiler.destinationExtension];
        }
    }

    if (fileOptions.destinationDirectory == nil) {
        // see if we can guess it
        NSString *guessedDirectory = nil;

        // 1) destination file already exists?
        NSString *derivedName = fileOptions.destinationName;
        NSArray *derivedPaths = [self.tree pathsOfFilesNamed:derivedName];
        if (derivedPaths.count > 0) {
            NSString *defaultDerivedFile = [[sourcePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileOptions.destinationName];

            if ([derivedPaths containsObject:defaultDerivedFile]) {
                guessedDirectory = [sourcePath stringByDeletingLastPathComponent];
                NSLog(@"Guessed output directory for %@ by existing output file in the same folder: %@", sourcePath, defaultDerivedFile);
            } else {
                NSArray *unoccupiedPaths = [derivedPaths filteredArrayUsingBlock:^BOOL(id value) {
                    NSString *derivedPath = value;
                    return [compilationOptions sourcePathThatCompilesInto:derivedPath] == nil;
                }];
                if (unoccupiedPaths.count == 1) {
                    guessedDirectory = [[unoccupiedPaths objectAtIndex:0] stringByDeletingLastPathComponent];
                    NSLog(@"Guessed output directory for %@ by existing output file %@", sourcePath, [unoccupiedPaths objectAtIndex:0]);
                }
            }
        }

        // 2) other files in the same folder have a common destination path?
        if (guessedDirectory == nil) {
            NSString *sourceDirectory = [sourcePath stringByDeletingLastPathComponent];
            NSArray *otherFiles = [[compilationOptions.compiler pathsOfSourceFilesInTree:self.tree] filteredArrayUsingBlock:^BOOL(id value) {
                return ![sourcePath isEqualToString:value] && [sourceDirectory isEqualToString:[value stringByDeletingLastPathComponent]];
            }];
            if ([otherFiles count] > 0) {
                NSArray *otherFileOptions = [otherFiles arrayByMappingElementsUsingBlock:^id(id otherFilePath) {
                    return [compilationOptions optionsForFileAtPath:otherFilePath create:NO];
                }];
                NSString *common = [FileCompilationOptions commonOutputDirectoryFor:otherFileOptions inProject:self];
                if ([common isEqualToString:@"__NONE_SET__"]) {
                    // nothing to figure it from
                } else if (common == nil) {
                    // different directories, something complicated is going on here;
                    // don't try to be too smart and just give up
                    NSLog(@"Refusing to guess output directory for %@ because other files in the same directory have varying output directories", sourcePath);
                    goto skipGuessing;
                } else {
                    guessedDirectory = common;
                    NSLog(@"Guessed output directory for %@ based on configuration of other files in the same directory", sourcePath);
                }
            }
        }

        // 3) are we in a subfolder with one of predefined 'output' names? (e.g. css/something.less)
        if (guessedDirectory == nil) {
            NSSet *magicNames = [NSSet setWithArray:compilationOptions.compiler.expectedOutputDirectoryNames];
            guessedDirectory = [self enumerateParentFoldersFromFolder:[sourcePath stringByDeletingLastPathComponent] with:^(NSString *folder, NSString *relativePath, BOOL *stop) {
                if ([magicNames containsObject:[folder lastPathComponent]]) {
                    NSLog(@"Guessed output directory for %@ to be its own parent folder (%@) based on being located inside a folder with magical name %@", sourcePath, [sourcePath stringByDeletingLastPathComponent], folder);
                    return (id)[sourcePath stringByDeletingLastPathComponent];
                }
                return (id)nil;
            }];
        }

        // 4) is there a sibling directory with one of predefined 'output' names? (e.g. smt/css/ for smt/src/foo/file.styl)
        if (guessedDirectory == nil) {
            NSSet *magicNames = [NSSet setWithArray:compilationOptions.compiler.expectedOutputDirectoryNames];
            guessedDirectory = [self enumerateParentFoldersFromFolder:[sourcePath stringByDeletingLastPathComponent] with:^(NSString *folder, NSString *relativePath, BOOL *stop) {
                NSString *parent = [folder stringByDeletingLastPathComponent];
                NSFileManager *fm = [NSFileManager defaultManager];
                for (NSString *magicName in magicNames) {
                    NSString *possibleDir = [parent stringByAppendingPathComponent:magicName];
                    BOOL isDir = NO;
                    if ([fm fileExistsAtPath:[_path stringByAppendingPathComponent:possibleDir] isDirectory:&isDir])
                        if (isDir) {
                            // TODO: decide whether or not to append relativePath based on existence of other files following the same convention
                            NSString *guess = [possibleDir stringByAppendingPathComponent:relativePath];
                            NSLog(@"Guessed output directory for %@ to be %@ based on a sibling folder with a magical name %@", sourcePath, guess, possibleDir);
                            return (id)guess;
                        }
                }
                return (id)nil;
            }];
        }

        // 5) if still nothing, put the result in the same folder
        if (guessedDirectory == nil) {
            guessedDirectory = [sourcePath stringByDeletingLastPathComponent];
        }

        if (guessedDirectory) {
            fileOptions.destinationDirectory = guessedDirectory;
        }
    }
skipGuessing:
    [pool drain];
    return fileOptions;
}

- (void)handleCompilationOptionsEnablementChanged {
    [self requestMonitoring:_compilationEnabled || _postProcessingEnabled forKey:CompilersEnabledMonitoringKey];
}

- (void)setCompilationEnabled:(BOOL)compilationEnabled {
    if (_compilationEnabled != compilationEnabled) {
        _compilationEnabled = compilationEnabled;
        [self handleCompilationOptionsEnablementChanged];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
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
    if (_fullPageReloadDelay != fullPageReloadDelay) {
        _fullPageReloadDelay = fullPageReloadDelay;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setEventProcessingDelay:(NSTimeInterval)eventProcessingDelay {
    if (_eventProcessingDelay != eventProcessingDelay) {
        _eventProcessingDelay = eventProcessingDelay;
        _monitor.eventProcessingDelay = _eventProcessingDelay;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setPostProcessingGracePeriod:(NSTimeInterval)postProcessingGracePeriod {
    if (postProcessingGracePeriod < 0.01)
        return;
    if (_postProcessingGracePeriod != postProcessingGracePeriod) {
        _postProcessingGracePeriod = postProcessingGracePeriod;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setRubyVersionIdentifier:(NSString *)rubyVersionIdentifier {
    if (_rubyVersionIdentifier != rubyVersionIdentifier) {
        [_rubyVersionIdentifier release], _rubyVersionIdentifier = [rubyVersionIdentifier copy];
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
    return [src stringByReplacingOccurrencesOfRegex:@"\\w" usingBlock:^NSString *(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
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
//            CompilationOptions *compilationOptions = [self optionsForCompiler:compiler create:NO];
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

        for (Compiler *compiler in [PluginManager sharedPluginManager].compilers) {
            if ([compiler.extensions containsObject:extension]) {
//                CompilationOptions *compilationOptions = [self optionsForCompiler:compiler create:NO];
//                CompilationMode mode = compilationOptions.mode;
                if (YES) { //mode == CompilationModeCompile || mode == CompilationModeMiddleware) {
                    return YES;
                }
            }
        }
        return NO;
    }];
    for (NSString *path in paths) {
        [self updateImportGraphForPath:path];
    }
    NSLog(@"Full import graph rebuild finished. %@", _importGraph);
}


#pragma mark - Post-processing

- (NSString *)postProcessingCommand {
    return _postProcessingCommand ?: @"";
}

- (void)setPostProcessingCommand:(NSString *)postProcessingCommand {
    if (postProcessingCommand != _postProcessingCommand) {
        [_postProcessingCommand release];
        _postProcessingCommand = [postProcessingCommand copy];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setPostProcessingScriptName:(NSString *)postProcessingScriptName {
    if (postProcessingScriptName != _postProcessingScriptName) {
        BOOL wasEmpty = (_postProcessingScriptName.length == 0);
        [_postProcessingScriptName release];
        _postProcessingScriptName = [postProcessingScriptName copy];
        if ([_postProcessingScriptName length] > 0 && wasEmpty && !_postProcessingEnabled) {
            [self setPostProcessingEnabled:YES];
        } else if ([_postProcessingScriptName length] == 0 && _postProcessingEnabled) {
            _postProcessingEnabled = NO;
        }
        [self handleCompilationOptionsEnablementChanged];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setPostProcessingEnabled:(BOOL)postProcessingEnabled {
    if ([_postProcessingScriptName length] == 0 && postProcessingEnabled) {
        return;
    }
    if (postProcessingEnabled != _postProcessingEnabled) {
        _postProcessingEnabled = postProcessingEnabled;
        [self handleCompilationOptionsEnablementChanged];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (UserScript *)postProcessingScript {
    if (_postProcessingScriptName.length == 0)
        return nil;

    NSArray *userScripts = [UserScriptManager sharedUserScriptManager].userScripts;
    for (UserScript *userScript in userScripts) {
        if ([userScript.uniqueName isEqualToString:_postProcessingScriptName])
            return userScript;
    }

    return [[[MissingUserScript alloc] initWithName:_postProcessingScriptName] autorelease];
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
        [_urlMasks release];
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


@end

*/