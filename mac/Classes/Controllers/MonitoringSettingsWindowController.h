
#import <Cocoa/Cocoa.h>

#import "BaseProjectSettingsWindowController.h"

@interface MonitoringSettingsWindowController : BaseProjectSettingsWindowController

@property (weak) IBOutlet NSTextField *builtInExtensionsLabelField;
@property (weak) IBOutlet NSTextField *additionalExtensionsTextField;

@property (weak) IBOutlet NSButton *disableLiveRefreshCheckBox;
@property (weak) IBOutlet NSButton *delayFullRefreshCheckBox;
@property (weak) IBOutlet NSTextField *fullRefreshDelayTextField;
@property (weak) IBOutlet NSButton *delayChangeProcessingButton;
@property (weak) IBOutlet NSTextField *changeProcessingDelayTextField;
@property (weak) IBOutlet NSButton *remoteServerWorkflowButton;

@property (weak) IBOutlet NSTableView *excludedPathsTableView;

@property (unsafe_unretained) IBOutlet NSTextView *superAdvancedOptionsTextView;
@property (weak) IBOutlet NSTextField *superAdvancedOptionsFeedbackTextField;

@end
