#import "Analytics.h"
@class Project;

@interface Analytics (SpecificEvents)

+ (void)initializeAnalyticsWithSpecificEvents;

+ (void)trackPossibleBrowserRefreshForProject:(Project *)project;

+ (void)trackCompilationWithCompilerNamed:(NSString *)compilerName forProject:(Project *)project;

+ (void)trackPostProcessing;

@end
