
#import "Project.h"
#import "FSMonitor.h"


@implementation Project

@synthesize path=_path;


#pragma mark -
#pragma mark Init/dealloc

- (id)initWithPath:(NSString *)path {
    if (self = [super init]) {
        _path = [path copy];
        _monitor = [[FSMonitor alloc] initWithPath:_path];
    }
    return self;
}

- (void)dealloc {
    [_path release], _path = nil;
    [_monitor release], _monitor = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark File System Monitoring


- (BOOL)isMonitoringEnabled {
    return _monitor.running;
}

- (void)setMonitoringEnabled:(BOOL)shouldMonitor {
    _monitor.running = shouldMonitor;
}


@end
