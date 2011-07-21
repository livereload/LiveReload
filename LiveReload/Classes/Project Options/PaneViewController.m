
#import "PaneViewController.h"


@implementation PaneViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil project:(Project *)project {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _project = [project retain];
    }
    return self;
}

- (void)dealloc {
    [_project release], _project = nil;
    [super dealloc];
}


#pragma mark - Pane options

- (NSString *)uniqueId {
    [NSException raise:@"MustBeOverridden" format:@"uniqueId must be overridden"];
    return @"?";
}

- (NSString *)title {
    return @"?";
}

- (NSString *)summary {
    return @"";
}

- (BOOL)isActive {
    return NO;
}


#pragma mark - Pane lifecycle

- (void)paneWillShow {
}

- (void)paneDidShow {
}

- (void)paneWillHide {
}

- (void)paneDidHide {
}

@end
