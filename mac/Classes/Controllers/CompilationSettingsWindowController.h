
#import <Cocoa/Cocoa.h>

#import "BaseProjectSettingsWindowController.h"


@interface CompilationSettingsWindowController : BaseProjectSettingsWindowController

@property (weak) IBOutlet NSPopUpButton *rubyVersionsPopUpButton;

@property (weak) IBOutlet NSTabView *tabView;
@property (weak) IBOutlet NSView *compilerSettingsTabView;
@property (weak) IBOutlet NSTableView *pathTableView;
@property (weak) IBOutlet NSButton *chooseFolderButton;

- (IBAction)chooseOutputFileName:(id)sender;

@end
