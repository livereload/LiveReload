
#import "PostProcessingSettingsWindowController.h"


@implementation PostProcessingSettingsWindowController {
    IBOutlet NSTextField *gracePeriod;
}

@synthesize commandField = _commandField;


#pragma mark - Actions

- (IBAction)showHelp:(id)sender {
    TenderShowArticle(@"features/custom-post-processing");
}


#pragma mark - Model sync

- (void)render {
    _commandField.stringValue = _project.postProcessingCommand;
    gracePeriod.doubleValue = _project.postProcessingGracePeriod;
}

- (void)save {
    _project.postProcessingCommand = _commandField.stringValue;
    _project.postProcessingGracePeriod = gracePeriod.doubleValue;
}


@end
