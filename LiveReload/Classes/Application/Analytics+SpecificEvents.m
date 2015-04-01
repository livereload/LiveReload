#import "Analytics+SpecificEvents.h"
#import "Workspace.h"
//@import ATCocoaLabs;

@implementation Analytics (SpecificEvents)

+ (void)trackPossibleBrowserRefresh {
    if ([Workspace sharedWorkspace].monitoringEnabled) {
        [Analytics trackEventNamed:@"refresh" parameters:@{}];
    }
}

+ (NSString *)today {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        [formatter setCalendar:[[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian]];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });
    return [formatter stringFromDate:[NSDate date]];
}

+ (void)eraseStaleData {
}

+ (void)trackCompilationWithCompilerNamed:(NSString *)compilerName {
//    [ATReducedPrecisionRange reducedPrecisionRangeStringForValue:7];
    [Analytics trackEventNamed:@"compilation" parameters:@{@"compiler": compilerName}];
}

+ (void)trackPostProcessing {
    [Analytics trackEventNamed:@"postproc" parameters:@{}];
}

+ (void)trackChangeInProject:(NSString *)projectPath {
    
}

@end
