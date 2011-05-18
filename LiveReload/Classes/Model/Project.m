
#import "Project.h"
#import "FSMonitor.h"
#import "CommunicationController.h"


#define PathKey @"path"


@interface Project () <FSMonitorDelegate>
@end


@implementation Project

@synthesize path=_path;


#pragma mark -
#pragma mark Init/dealloc

- (void)initializeMonitoring {
    _monitor = [[FSMonitor alloc] initWithPath:_path];
    _monitor.delegate = self;
}

- (id)initWithPath:(NSString *)path {
    if ((self = [super init])) {
        _path = [path copy];
        [self initializeMonitoring];
    }
    return self;
}

- (void)dealloc {
    [_path release], _path = nil;
    [_monitor release], _monitor = nil;
    [super dealloc];
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
    [[CommunicationController sharedCommunicationController] broadcastChangedPathes:pathes inProject:self];
}


@end
