
#import "ToolOutputWindowController.h"

#import "PluginManager.h"

#import "Project.h"
#import "OldFSMonitor.h"
#import "OldFSTreeFilter.h"
#import "OldFSTree.h"
#import "Preferences.h"
#import "PluginManager.h"
#import "Compiler.h"
#import "CompilationOptions.h"
#import "FileCompilationOptions.h"
#import "ImportGraph.h"
#import "ToolOutput.h"

#import "Stats.h"
#import "RegexKitLite.h"
#import "NSArray+Substitutions.h"
#import "NSTask+OneLineTasksWithOutput.h"
#import "ATFunctionalStyle.h"
#import "FixUnixPath.h"

#include <stdbool.h>
#include "common.h"
#include "sglib.h"
#include "console.h"
#include "stringutil.h"
#include "reload_request.h"
#include "communication.h"
#include "eventbus.h"


#define kPostProcessingSafeInterval 0.5l


#define PathKey @"path"

NSString *ProjectDidDetectChangeNotification = @"ProjectDidDetectChangeNotification";
NSString *ProjectWillBeginCompilationNotification = @"ProjectWillBeginCompilationNotification";
NSString *ProjectDidEndCompilationNotification = @"ProjectDidEndCompilationNotification";
NSString *ProjectMonitoringStateDidChangeNotification = @"ProjectMonitoringStateDidChangeNotification";
NSString *ProjectNeedsSavingNotification = @"ProjectNeedsSavingNotification";
EVENTBUS_DEFINE_EVENT(project_fs_change_event);

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

@end


@implementation Project

@synthesize path=_path;
@synthesize dirty=_dirty;
@synthesize lastSelectedPane=_lastSelectedPane;
@synthesize enabled=_enabled;
@synthesize compilationEnabled=_compilationEnabled;
@synthesize postProcessingCommand=_postProcessingCommand;
@synthesize postProcessingEnabled=_postProcessingEnabled;
@synthesize disableLiveRefresh=_disableLiveRefresh;
@synthesize enableRemoteServerWorkflow=_enableRemoteServerWorkflow;
@synthesize fullPageReloadDelay=_fullPageReloadDelay;
@synthesize eventProcessingDelay=_eventProcessingDelay;
@synthesize rubyVersionIdentifier=_rubyVersionIdentifier;
@synthesize numberOfPathComponentsToUseAsName=_numberOfPathComponentsToUseAsName;
@synthesize customName=_customName;


#pragma mark -
#pragma mark Init/dealloc

- (id)initWithPath:(NSString *)path memento:(NSDictionary *)memento {
    if ((self = [super init])) {
        _path = [path copy];
        _enabled = YES;
        _session = reload_session_create(self);

        _monitor = [[FSMonitor alloc] initWithPath:_path];
        _monitor.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFilter) name:PreferencesFilterSettingsChangedNotification object:nil];
        [self updateFilter];

        _compilerOptions = [[NSMutableDictionary alloc] init];
        _monitoringRequests = [[NSMutableSet alloc] init];

        _lastSelectedPane = [[memento objectForKey:@"last_pane"] copy];

        id raw = [memento objectForKey:@"compilers"];
        if (raw) {
            PluginManager *pluginManager = [PluginManager sharedPluginManager];
            [raw enumerateKeysAndObjectsUsingBlock:^(id uniqueId, id compilerMemento, BOOL *stop) {
                Compiler *compiler = [pluginManager compilerWithUniqueId:uniqueId];
                if (compiler) {
                    [_compilerOptions setObject:[[[CompilationOptions alloc] initWithCompiler:compiler memento:compilerMemento] autorelease] forKey:uniqueId];
                } else {
                    // TODO: save data for unknown compilers and re-add them when creating a memento
                }
            }];
        }

        if ([memento objectForKey:@"compilationEnabled"]) {
            _compilationEnabled = [[memento objectForKey:@"compilationEnabled"] boolValue];
        } else {
            _compilationEnabled = NO;
            [[memento objectForKey:@"compilers"] enumerateKeysAndObjectsUsingBlock:^(id uniqueId, id compilerMemento, BOOL *stop) {
                if ([[compilerMemento objectForKey:@"mode"] isEqualToString:@"compile"]) {
                    _compilationEnabled = YES;
                }
            }];
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
        _monitor.eventProcessingDelay = _eventProcessingDelay;

        _postProcessingCommand = [[memento objectForKey:@"postproc"] copy];
        if ([memento objectForKey:@"postprocEnabled"]) {
            _postProcessingEnabled = [[memento objectForKey:@"postprocEnabled"] boolValue];
        } else {
            _postProcessingEnabled = [_postProcessingCommand length] > 0;
        }

        if ([memento objectForKey:@"rubyVersion"])
            _rubyVersionIdentifier = [[memento objectForKey:@"rubyVersion"] copy];
        else
            _rubyVersionIdentifier = @"system";

        _importGraph = [[ImportGraph alloc] init];

        NSArray *excludedPaths = [memento objectForKey:@"excludedPaths"];
        if (excludedPaths == nil)
            excludedPaths = [NSArray array];
        _excludedFolderPaths = [[NSMutableArray alloc] initWithArray:excludedPaths];
        
        _numberOfPathComponentsToUseAsName = [[memento objectForKey:@"numberOfPathComponentsToUseAsName"] integerValue];
        if (_numberOfPathComponentsToUseAsName == 0)
            _numberOfPathComponentsToUseAsName = 1;
        
        _customName = [memento objectForKey:@"customName"] ?: @"";

        [self handleCompilationOptionsEnablementChanged];
    }
    return self;
}

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(broadcastPendingChanges) object:nil];
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

- (NSDictionary *)memento {
    NSMutableDictionary *memento = [NSMutableDictionary dictionary];
    [memento setObject:[_compilerOptions dictionaryByMappingValuesToSelector:@selector(memento)] forKey:@"compilers"];
    if (_lastSelectedPane)
        [memento setObject:_lastSelectedPane forKey:@"last_pane"];
    if ([_postProcessingCommand length] > 0) {
        [memento setObject:_postProcessingCommand forKey:@"postproc"];
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
    if ([_excludedFolderPaths count] > 0) {
        [memento setObject:_excludedFolderPaths forKey:@"excludedPaths"];
    }
    [memento setObject:_rubyVersionIdentifier forKey:@"rubyVersion"];
    [memento setObject:[NSNumber numberWithBool:_compilationEnabled ] forKey:@"compilationEnabled"];
    
    [memento setObject:[NSNumber numberWithInteger:_numberOfPathComponentsToUseAsName] forKey:@"numberOfPathComponentsToUseAsName"];
    if (_customName.length > 0)
        [memento setObject:_customName forKey:@"customName"];
    
    return [NSDictionary dictionaryWithDictionary:memento];
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

- (void)broadcastPendingChanges {
    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidDetectChangeNotification object:self];
    eventbus_post(project_fs_change_event, NULL);
    comm_broadcast_reload_requests(_session);
    reload_session_clear(_session);
    StatIncrement(BrowserRefreshCountStat, 1);
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

- (void)processChangeAtPath:(NSString *)relativePath {
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
                reload_session_add(_session, reload_request_create([derivedName UTF8String], [[_path stringByAppendingPathComponent:relativePath] UTF8String]));
                NSLog(@"Broadcasting a fake change in %@ instead of %@ (compiler %@).", derivedName, relativePath, compiler.name);
                StatGroupIncrement(CompilerChangeCountStatGroup, compiler.uniqueId, 1);
                break;
//            } else if (compilationOptions.mode == CompilationModeDisabled) {
//                compilerFound = NO;
            }
        }
    }

    if (!compilerFound) {
        reload_session_add(_session, reload_request_create([[_path stringByAppendingPathComponent:relativePath] UTF8String], NULL));
    }
}

// I don't think this will ever be needed, but not throwing the code away yet
#ifdef AUTORESCAN_WORKAROUND_ENABLED
- (void)rescanRecentlyChangedPaths {
    NSLog(@"Rescanning %@ again in case some compiler was slow to write the changes.", _path);
    [_monitor rescan];
}
#endif

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChangeAtPathes:(NSSet *)pathes {
    switch (pathes.count) {
        case 0:  break;
        case 1:  console_printf("Changed: %s", [[pathes anyObject] UTF8String]); break;
        default: console_printf("Changed: %s and %d others", [[pathes anyObject] UTF8String], pathes.count - 1); break;
    }

    [self updateImportGraphForPaths:pathes];

#ifdef AUTORESCAN_WORKAROUND_ENABLED
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(rescanRecentlyChangedPaths) object:nil];
    [self performSelector:@selector(rescanRecentlyChangedPaths) withObject:nil afterDelay:1.0];
#endif

    for (NSString *relativePath in pathes) {
        NSSet *realPaths = [_importGraph rootReferencingPathsForPath:relativePath];
        if ([realPaths count] > 0) {
            NSLog(@"Instead of imported file %@, processing changes in %@", relativePath, [[realPaths allObjects] componentsJoinedByString:@", "]);
            for (NSString *path in realPaths) {
                [self processChangeAtPath:path];
            }
        } else {
            [self processChangeAtPath:relativePath];
        }

    }
    if (reload_session_empty(_session)) {
        goto fin;
    }

    if ([_postProcessingCommand length] > 0 && _postProcessingEnabled) {
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        if (_lastPostProcessingRunDate == 0 || (now - _lastPostProcessingRunDate >= kPostProcessingSafeInterval)) {

            NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         @"/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby", @"$(ruby)",
                                         [[NSBundle mainBundle] pathForResource:@"node" ofType:nil], @"$(node)",
                                         _path, @"$(project_dir)",
                                         nil];

            NSString *command = [_postProcessingCommand stringBySubstitutingValuesFromDictionary:info];
            NSString *shell = DetermineShell();
            NSLog(@"Running post-processing command: %@", command);

            NSString *runDirectory = _path;
            NSString *prefix = @"which rvm >/dev/null || source \"$HOME/.rvm/scripts/rvm\"; ";
            NSArray *shArgs = [NSArray arrayWithObjects:@"--login",@"-i",@"-c", [prefix stringByAppendingString:command], nil];

            NSError *error = nil;
            NSString *pwd = [[NSFileManager defaultManager] currentDirectoryPath];
            [[NSFileManager defaultManager] changeCurrentDirectoryPath:runDirectory];
            const char *project_path = [self.path UTF8String];
            console_printf("Post-proc exec: %s --login -c \"%s\"", [shell UTF8String], str_collapse_paths([command UTF8String], project_path));
            NSString *output = [NSTask stringByLaunchingPath:shell
                                               withArguments:shArgs
                                                       error:&error];
            [[NSFileManager defaultManager] changeCurrentDirectoryPath:pwd];

            if ([output length] > 0) {
                console_printf("\n%s\n\n", str_collapse_paths([output UTF8String], project_path));
                NSLog(@"Post-processing output:\n%@\n", output);
            }
            if (error) {
                console_printf("Post-processor failed.");
                NSLog(@"Error: %@", [error description]);
            }

            _lastPostProcessingRunDate = [NSDate timeIntervalSinceReferenceDate];
        } else {
            console_printf("Skipping post-processing (only %.1fs since last run)", now - _lastPostProcessingRunDate);
        }
    }

    BOOL isFullReload = NO;
    if (_disableLiveRefresh) {
        isFullReload = YES;
    } else {
        isFullReload = !reload_session_can_refresh_live(_session);
    }

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(broadcastPendingChanges) object:nil];
    if (isFullReload && _fullPageReloadDelay > 0.001) {
        [self performSelector:@selector(broadcastPendingChanges) withObject:nil afterDelay:_fullPageReloadDelay];
    } else {
        [self broadcastPendingChanges];
    }

fin:
    ;
}

- (FSTree *)tree {
    return _monitor.tree;
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
        NSString *derivedPath = [self.tree pathOfFileNamed:derivedName];

        if (derivedPath) {
            guessedDirectory = [derivedPath stringByDeletingLastPathComponent];
            NSLog(@"Guessed output directory for %@ by existing output file %@", sourcePath, derivedPath);
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

        // TODO match fragments
        NSString *name = [pathFragment lastPathComponent];
        NSString *path = [_monitor.tree pathOfFileNamed:name];
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
        BOOL wasEmpty = (_postProcessingCommand.length == 0);
        [_postProcessingCommand release];
        _postProcessingCommand = [postProcessingCommand copy];
        if ([_postProcessingCommand length] > 0 && wasEmpty && !_postProcessingEnabled) {
            [self setPostProcessingEnabled:YES];
        } else if ([_postProcessingCommand length] == 0 && _postProcessingEnabled) {
            _postProcessingEnabled = NO;
        }
        [self handleCompilationOptionsEnablementChanged];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
}

- (void)setPostProcessingEnabled:(BOOL)postProcessingEnabled {
    if ([_postProcessingCommand length] == 0 && postProcessingEnabled) {
        return;
    }
    if (postProcessingEnabled != _postProcessingEnabled) {
        _postProcessingEnabled = postProcessingEnabled;
        [self handleCompilationOptionsEnablementChanged];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
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


@end
