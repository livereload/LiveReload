
#import "Project.h"
#import "FSMonitor.h"
#import "FSTreeFilter.h"
#import "FSTree.h"
#import "CommunicationController.h"
#import "Preferences.h"
#import "PluginManager.h"
#import "Compiler.h"
#import "CompilationOptions.h"


#define PathKey @"path"

NSString *ProjectDidDetectChangeNotification = @"ProjectDidDetectChangeNotification";
NSString *ProjectMonitoringStateDidChangeNotification = @"ProjectMonitoringStateDidChangeNotification";

static NSString *CompilersEnabledMonitoringKey = @"someCompilersEnabled";



@interface Project () <FSMonitorDelegate>

- (void)updateFilter;
- (void)handleCompilationOptionsEnablementChanged:(NSNotification *)notification;

@end


@implementation Project

@synthesize path=_path;


#pragma mark -
#pragma mark Init/dealloc

- (void)initializeMonitoring {
    _monitor = [[FSMonitor alloc] initWithPath:_path];
    _monitor.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFilter) name:PreferencesFilterSettingsChangedNotification object:nil];
    [self updateFilter];

    _compilerOptions = [[NSMutableDictionary alloc] init];
    _monitoringRequests = [[NSMutableSet alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleCompilationOptionsEnablementChanged:) name:CompilationOptionsEnabledChangedNotification object:nil];
    [self handleCompilationOptionsEnablementChanged:nil];
}

- (id)initWithPath:(NSString *)path {
    if ((self = [super init])) {
        _path = [path copy];
        [self initializeMonitoring];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_path release], _path = nil;
    [_monitor release], _monitor = nil;
    [super dealloc];
}


#pragma mark - Displaying

- (NSString *)displayPath {
    return [_path stringByAbbreviatingWithTildeInPath];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Project(%@)", [self displayPath]];
}


#pragma mark - Filtering

- (void)updateFilter {
    _monitor.filter.ignoreHiddenFiles = YES;
    _monitor.filter.enabledExtensions = [Preferences sharedPreferences].allExtensions;
    _monitor.filter.excludedNames = [Preferences sharedPreferences].excludedNames;
    [_monitor filterUpdated];
}


#pragma mark -
#pragma mark Persistence

- (id)initWithMemento:(NSDictionary *)memento {
    if ((self = [super init])) {
        _path = [[memento objectForKey:PathKey] copy];
        [self initializeMonitoring];
    }
    return self;
}

- (NSDictionary *)memento {
    return [NSDictionary dictionaryWithObjectsAndKeys:_path, PathKey, nil];
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
    for (NSString *path in pathes) {
        Compiler *compiler = [[PluginManager sharedPluginManager] compilerForExtension:[path pathExtension]];
        if (compiler) {
            NSString *derivedName = [compiler derivedNameForFile:path];
            NSString *derivedPath = [_monitor.tree pathOfFileNamed:derivedName];
            if (derivedPath) {
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
        options = [[CompilationOptions alloc] initWithCompiler:compiler dictionary:nil];
        [_compilerOptions setObject:options forKey:uniqueId];
    }
    return options;
}

- (void)handleCompilationOptionsEnablementChanged:(NSNotification *)notification {
    [self requestMonitoring:[self areAnyCompilersEnabled] forKey:CompilersEnabledMonitoringKey];
}


@end
