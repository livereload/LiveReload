#import "Analytics.h"

@interface Analytics (SpecificEvents)

+ (void)trackPossibleBrowserRefresh;

+ (void)trackCompilationWithCompilerNamed:(NSString *)compilerName;

@end
