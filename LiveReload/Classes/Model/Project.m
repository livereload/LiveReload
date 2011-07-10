
#import "PluginManager.h"

#import "Project.h"
#import "FSMonitor.h"
#import "FSTreeFilter.h"
#import "FSTree.h"
#import "CommunicationController.h"
#import "Preferences.h"
#import "PluginManager.h"
#import "Compiler.h"
#import "CompilationOptions.h"

#import "ATFunctionalStyle.h"


#define PathKey @"path"

NSString *ProjectDidDetectChangeNotification = @"ProjectDidDetectChangeNotification";
NSString *ProjectMonitoringStateDidChangeNotification = @"ProjectMonitoringStateDidChangeNotification";
NSString *ProjectNeedsSavingNotification = @"ProjectNeedsSavingNotification";

static NSString *CompilersEnabledMonitoringKey = @"someCompilersEnabled";



@interface Project () <FSMonitorDelegate>

- (void)updateFilter;
- (void)handleCompilationOptionsEnablementChanged:(NSNotification *)notification;

@end


@implementation Project

@synthesize path=_path;
@synthesize dirty=_dirty;
@synthesize lastSelectedPane=_lastSelectedPane;


#pragma mark -
#pragma mark Init/dealloc

- (id)initWithPath:(NSString *)path memento:(NSDictionary *)memento {
    if ((self = [super init])) {
        _path = [path copy];

        _monitor = [[FSMonitor alloc] initWithPath:_path];
        _monitor.delegate = self;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFilter) name:PreferencesFilterSettingsChangedNotification object:nil];
        [self updateFilter];

        _compilerOptions = [[NSMutableDictionary alloc] init];
        _monitoringRequests = [[NSMutableSet alloc] init];

        _lastSelectedPane = [[memento objectForKey:@"lastSelectedPane"] copy];

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

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCompilationOptionsEnablementChanged:) name:CompilationOptionsEnabledChangedNotification object:nil];
        [self handleCompilationOptionsEnablementChanged:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_path release], _path = nil;
    [_monitor release], _monitor = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Persistence

- (NSDictionary *)memento {
    NSMutableDictionary *memento = [NSMutableDictionary dictionary];
    [memento setObject:[_compilerOptions dictionaryByMappingValuesToSelector:@selector(memento)] forKey:@"compilers"];
    if (_lastSelectedPane)
        [memento setObject:_lastSelectedPane forKey:@"last_pane"];
    return [NSDictionary dictionaryWithDictionary:memento];
}


#pragma mark - Displaying

- (NSString *)displayPath {
    return [_path stringByAbbreviatingWithTildeInPath];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Project(%@)", [self displayPath]];
}

- (NSComparisonResult)compareByDisplayPath:(Project *)another {
    return [self.displayPath compare:another.displayPath];
}


#pragma mark - Filtering

- (void)updateFilter {
    _monitor.filter.ignoreHiddenFiles = YES;
    _monitor.filter.enabledExtensions = [Preferences sharedPreferences].allExtensions;
    _monitor.filter.excludedNames = [Preferences sharedPreferences].excludedNames;
    [_monitor filterUpdated];
}


#pragma mark -
#pragma mark File System Monitoring

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
            [[NSNotificationCenter defaultCenter] postNotificationName:ProjectMonitoringStateDidChangeNotification object:self];
        }
    }
}

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChangeAtPathes:(NSSet *)pathes {
    NSMutableSet *filtered = [NSMutableSet setWithCapacity:[pathes count]];
    NSString *rootPath = monitor.tree.rootPath;
    for (NSString *path in pathes) {
        path = [rootPath stringByAppendingPathComponent:path];
        Compiler *compiler = [[PluginManager sharedPluginManager] compilerForExtension:[path pathExtension]];
        if (compiler) {
            NSString *derivedName = [compiler derivedNameForFile:path];
            NSString *derivedPath = [_monitor.tree pathOfFileNamed:derivedName];
            if (derivedPath) {
                derivedPath = [rootPath stringByAppendingPathComponent:derivedPath];
                [compiler compile:path into:derivedPath];
            }
        } else {
            [filtered addObject:path];
        }
    }
    if ([filtered count] == 0) {
        return;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidDetectChangeNotification object:self];
    [[CommunicationController sharedCommunicationController] broadcastChangedPathes:filtered inProject:self];
}

- (FSTree *)tree {
    return _monitor.tree;
}


#pragma mark - Options

- (BOOL)areAnyCompilersEnabled {
    for (CompilationOptions *options in [_compilerOptions allValues]) {
        if (options.enabled) {
            return YES;
        }
    }
    return NO;
}

- (CompilationOptions *)optionsForCompiler:(Compiler *)compiler create:(BOOL)create {
    NSString *uniqueId = compiler.uniqueId;
    CompilationOptions *options = [_compilerOptions objectForKey:uniqueId];
    if (options == nil && create) {
        options = [[CompilationOptions alloc] initWithCompiler:compiler memento:nil];
        [_compilerOptions setObject:options forKey:uniqueId];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SomethingChanged" object:self];
    }
    return options;
}

- (void)handleCompilationOptionsEnablementChanged:(NSNotification *)notification {
    [self requestMonitoring:[self areAnyCompilersEnabled] forKey:CompilersEnabledMonitoringKey];
}

- (NSString *)relativePathForPath:(NSString *)path {
    NSString *root = [_path stringByResolvingSymlinksInPath];
    path = [path stringByResolvingSymlinksInPath];

    if ([root isEqualToString:path]) {
        return @"/";
    }

    NSArray *rootComponents = [root pathComponents];
    NSArray *pathComponents = [path pathComponents];

    NSInteger pathCount = [pathComponents count];
    NSInteger rootCount = [rootComponents count];
    if (pathCount > rootCount) {
        if ([rootComponents isEqualToArray:[pathComponents subarrayWithRange:NSMakeRange(0, rootCount)]]) {
            return [[pathComponents subarrayWithRange:NSMakeRange(rootCount, pathCount - rootCount)] componentsJoinedByString:@"/"];
        }
    }
    return nil;
}

@end
