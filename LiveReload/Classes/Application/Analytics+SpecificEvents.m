#import "Analytics+SpecificEvents.h"
#import "Workspace.h"

@implementation Analytics (SpecificEvents)

+ (void)trackPossibleBrowserRefresh {
    if ([Workspace sharedWorkspace].monitoringEnabled) {
        [Analytics trackEventNamed:@"refresh" parameters:@{}];
    }
}

+ (void)trackCompilationWithCompilerNamed:(NSString *)compilerName {
    [Analytics trackEventNamed:@"compilation" parameters:@{@"compiler": compilerName}];
}

@end
