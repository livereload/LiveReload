
#import "BaseProjectSettingsWindowController.h"


@implementation BaseProjectSettingsWindowController


#pragma mark - Opening/closing

- (id)initWithProject:(Project *)project {
    self = [super initWithWindowNibName:NSStringFromClass([self class])];
    if (self) {
        _project = [project retain];
    }
    return self;
}

- (void)dealloc {
    [_project release], _project = nil;
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];

    [self render];
}


#pragma mark - Actions

- (IBAction)dismiss:(id)sender {
    [self save];
    [NSApp endSheet:[self window]];
}

- (IBAction)showHelp:(id)sender {
}


#pragma mark - Model sync

- (void)render {
}

- (void)save {
}


@end
