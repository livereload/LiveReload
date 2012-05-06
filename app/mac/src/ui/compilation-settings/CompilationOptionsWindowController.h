
#import <Cocoa/Cocoa.h>

@interface CompilationOptionsWindowController : NSWindowController {
    IBOutlet NSButton *apply;
    IBOutlet NSButton *help;

    IBOutlet NSPopUpButton *rubyVersions;

    IBOutlet NSTabView *tabs;


    IBOutlet NSView *compilerOptions;


    IBOutlet NSTableView *outputPaths;
    IBOutlet NSButton *setOutputFolder;
    IBOutlet NSButton *setOutputFile;

    IBOutlet NSTextField *mask;
    IBOutlet NSButton *applyMask;
}
@end
