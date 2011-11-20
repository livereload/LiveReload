
#import <Cocoa/Cocoa.h>

#import "BaseProjectSettingsWindowController.h"


@interface CompilationSettingsWindowController : BaseProjectSettingsWindowController

@property (assign) IBOutlet NSPopUpButton *nodeVersionsPopUpButton;

@property (assign) IBOutlet NSPopUpButton *rubyVersionsPopUpButton;

@property (assign) IBOutlet NSTabView *tabView;
@property (assign) IBOutlet NSView *compilerSettingsTabView;
@property (assign) IBOutlet NSTableView *pathTableView;
@property (assign) IBOutlet NSButton *chooseFolderButton;

@end
