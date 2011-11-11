
#import <Cocoa/Cocoa.h>

#import "BaseProjectSettingsWindowController.h"

@interface MonitoringSettingsWindowController : BaseProjectSettingsWindowController

@property (assign) IBOutlet NSTextField *builtInExtensionsLabelField;
@property (assign) IBOutlet NSTextField *additionalExtensionsTextField;

@property (assign) IBOutlet NSButton *disableLiveRefreshCheckBox;
@property (assign) IBOutlet NSButton *delayFullRefreshCheckBox;
@property (assign) IBOutlet NSTextField *fullRefreshDelayTextField;

@end
