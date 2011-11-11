
#import <Cocoa/Cocoa.h>

#import "BaseProjectSettingsWindowController.h"


@interface CompilationSettingsWindowController : BaseProjectSettingsWindowController

@property (assign) IBOutlet NSPopUpButton *nodeVersionsPopUpButton;

@property (assign) IBOutlet NSPopUpButton *rubyVersionsPopUpButton;

@end
