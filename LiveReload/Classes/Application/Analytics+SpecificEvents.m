#import "Analytics+SpecificEvents.h"
#import "Workspace.h"
#import "Project.h"


#include <tgmath.h>
#define ATFloatZero(a) (fabs(a) <= 1e-6)


@implementation Analytics (SpecificEvents)

+ (void)initializeAnalyticsWithSpecificEvents {
    // N.B.: Parse only supports 8 custom properties, and we add 'os' and 'licensing' props internally
    [Analytics addFlagNamed:@"compilerUsed"];
    [Analytics addFlagNamed:@"postprocUsed"];
    [Analytics addCounterNamed:@"refreshes"];
    [Analytics addCounterNamed:@"compilations"];
    [Analytics addCountingSetNamed:@"activeProjects"];
    [Analytics addPropertiesBlock:^(NSMutableDictionary *parameters) {
        parameters[@"totalProjects"] = @([Workspace sharedWorkspace].projects.count);
    }];

    [Analytics addPeriod:[[ATAnalyticsPeriod alloc] initWithIdentifier:@"daily" calendarUnits:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay]];
    [Analytics addPeriod:[[ATAnalyticsPeriod alloc] initWithIdentifier:@"weekly" calendarUnits:NSCalendarUnitYearForWeekOfYear | NSCalendarUnitWeekOfYear]];
    [Analytics addPeriod:[[ATAnalyticsPeriod alloc] initWithIdentifier:@"monthly" calendarUnits:NSCalendarUnitYear | NSCalendarUnitMonth]];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"com.livereload.debug.analytics.minutely"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"com.livereload.debug.analytics.logEvents"]) {
        [Analytics addPeriod:[[ATAnalyticsPeriod alloc] initWithIdentifier:@"minutely" calendarUnits:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute]];
    }
}

+ (void)trackPossibleBrowserRefreshForProject:(Project *)project {
    BOOL browsersConnected = [Workspace sharedWorkspace].monitoringEnabled;

    if (browsersConnected) {
        [Analytics trackEventNamed:@"refresh" parameters:@{}];
        [Analytics incrementCounterNamed:@"refreshes"];
        [Analytics includeValue:project.path intoCountingSetNamed:@"activeProjects"];
    }
}

+ (void)trackCompilationWithCompilerNamed:(NSString *)compilerName forProject:(Project *)project {
    [Analytics trackEventNamed:@"compilation" parameters:@{@"compiler": compilerName}];
    [Analytics setFlagNamed:@"compilerUsed"];
    [Analytics incrementCounterNamed:@"compilations"];
    [Analytics includeValue:project.path intoCountingSetNamed:@"activeProjects"];
}

+ (void)trackPostProcessing {
    [Analytics trackEventNamed:@"postproc" parameters:@{}];
    [Analytics setFlagNamed:@"postprocUsed"];
}

@end
