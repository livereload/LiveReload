
#import <Cocoa/Cocoa.h>

@interface MonitoringSettingsWindowController : NSWindowController

@property (assign) IBOutlet NSTextField *builtInExtensionsLabelField;
@property (assign) IBOutlet NSTextField *additionalExtensionsTextField;

@property (assign) IBOutlet NSButton *disableLiveRefreshCheckBox;
@property (assign) IBOutlet NSButton *delayFullRefreshCheckBox;
@property (assign) IBOutlet NSTextField *fullRefreshDelayTextField;
@property (assign) IBOutlet NSButton *delayChangeProcessingButton;
@property (assign) IBOutlet NSTextField *changeProcessingDelayTextField;
@property (assign) IBOutlet NSButton *remoteServerWorkflowButton;

@property (assign) IBOutlet NSTableView *excludedPathsTableView;

@end
