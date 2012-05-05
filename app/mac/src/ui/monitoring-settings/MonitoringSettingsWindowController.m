
#import "MonitoringSettingsWindowController.h"


@implementation MonitoringSettingsWindowController {
    
    IBOutlet NSButton *applyButton;
}

@synthesize builtInExtensionsLabelField=_builtInExtensionsLabelField;
@synthesize additionalExtensionsTextField = _additionalExtensionsTextField;
@synthesize disableLiveRefreshCheckBox = _disableLiveRefreshCheckBox;
@synthesize delayFullRefreshCheckBox = _delayFullRefreshCheckBox;
@synthesize fullRefreshDelayTextField = _fullRefreshDelayTextField;
@synthesize delayChangeProcessingButton = _delayChangeProcessingButton;
@synthesize changeProcessingDelayTextField = _changeProcessingDelayTextField;
@synthesize remoteServerWorkflowButton = _remoteServerWorkflowButton;
@synthesize excludedPathsTableView = _excludedPathsTableView;

@end
