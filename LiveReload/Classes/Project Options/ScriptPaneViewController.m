
#import "ScriptPaneViewController.h"
#import "Project.h"


@implementation ScriptPaneViewController

- (id)initWithProject:(Project *)project {
    self = [super initWithNibName:@"ScriptPaneViewController" bundle:nil project:project];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}


#pragma mark - Pane options

- (NSString *)uniqueId {
    return @"postproc";
}

- (NSString *)title {
    return @"Post-proc";
}

- (NSString *)summary {
    NSString *command = _project.postProcessingCommand;
    if ([command length] == 0)
        return @"";
    else {
        NSString *firstArg = [[command componentsSeparatedByString:@" "] objectAtIndex:0];
        return [firstArg lastPathComponent];
    }
}

+ (NSSet *)keyPathsForValuesAffectingSummary {
    return [NSSet setWithObject:@"project.postProcessingCommand"];
}

- (BOOL)isActive {
    return [_project.postProcessingCommand length] > 0;
}

+ (NSSet *)keyPathsForValuesAffectingActive {
    return [NSSet setWithObject:@"project.postProcessingCommand"];
}

@end
