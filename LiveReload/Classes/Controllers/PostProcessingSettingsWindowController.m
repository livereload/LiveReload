
#import "PostProcessingSettingsWindowController.h"


@implementation PostProcessingSettingsWindowController

@synthesize commandField = _commandField;


#pragma mark - Actions

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
