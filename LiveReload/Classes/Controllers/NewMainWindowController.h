
#import <Cocoa/Cocoa.h>

@interface NewMainWindowController : NSWindowController {
    NSObject              *_projectsItem;
    NSImage               *_folderImage;
}

@property (nonatomic, readonly) NSArray *projects;

@property (assign) IBOutlet NSOutlineView *projectOutlineView;

@property (assign) IBOutlet NSTextField *pathTextField;

@property (assign) IBOutlet NSButton *compilerEnabledCheckBox;

@property (assign) IBOutlet NSButton *postProcessingEnabledCheckBox;

@end
