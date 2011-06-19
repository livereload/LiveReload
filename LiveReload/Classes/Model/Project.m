
#import "Project.h"
#import "FSMonitor.h"
#import "FSTreeFilter.h"
#import "CommunicationController.h"
#import "Preferences.h"


#define PathKey @"path"

NSString *ProjectDidDetectChangeNotification = @"ProjectDidDetectChangeNotification";



@interface Project () <FSMonitorDelegate>

- (void)updateFilter;

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

- (BOOL)isMonitoringEnabled {
    return _monitor.running;
}

- (void)setMonitoringEnabled:(BOOL)shouldMonitor {
    _monitor.running = shouldMonitor;
}

- (void)fileSystemMonitor:(FSMonitor *)monitor detectedChangeAtPathes:(NSSet *)pathes {
    [[NSNotificationCenter defaultCenter] postNotificationName:ProjectDidDetectChangeNotification object:self];
    [[CommunicationController sharedCommunicationController] broadcastChangedPathes:pathes inProject:self];
}


@end
