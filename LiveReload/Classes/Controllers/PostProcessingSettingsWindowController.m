
#import "PostProcessingSettingsWindowController.h"

#import "Project.h"

#import "ShitHappens.h"


@interface PostProcessingSettingsWindowController ()

- (void)render;
- (void)save;

@end



@implementation PostProcessingSettingsWindowController

@synthesize commandField = _commandField;


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
    TenderShowArticle(@"features/custom-post-processing");
}


#pragma mark - Model sync

- (void)render {
    _commandField.stringValue = _project.postProcessingCommand;
}

- (void)save {
    _project.postProcessingCommand = _commandField.stringValue;
}


@end
