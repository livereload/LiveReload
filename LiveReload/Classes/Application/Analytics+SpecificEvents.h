#import "Analytics.h"
@class Project;

@interface Analytics (SpecificEvents)

+ (void)initializeAnalyticsWithSpecificEvents;

+ (void)trackPossibleBrowserRefreshForProject:(Project *)project;

+ (void)trackCompilationWithCompilerNamed:(NSString *)compilerName forProjectPath:(NSString *)projectPath;

+ (void)trackPostProcessing;

@end
