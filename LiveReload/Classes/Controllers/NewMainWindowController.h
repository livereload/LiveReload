
#import <Cocoa/Cocoa.h>


@class Project;


@interface NewMainWindowController : NSWindowController {
    NSObject              *_projectsItem;
    NSImage               *_folderImage;

    NSArray               *_projects;
    Project               *_selectedProject;

    NSArray               *_panes;
    NSInteger              _currentPane;
}

@property (assign) IBOutlet NSBox *paneBorderBox;
@property (assign) IBOutlet NSView *panePlaceholder;

// welcome pane
@property (assign) IBOutlet NSView *welcomePane;
@property (assign) IBOutlet NSTextField *welcomeMessageField;

// project pane
@property (assign) IBOutlet NSView *projectPane;
@property (assign) IBOutlet NSOutlineView *projectOutlineView;
@property (assign) IBOutlet NSTextField *pathTextField;
@property (assign) IBOutlet NSButton *compilerEnabledCheckBox;
@property (assign) IBOutlet NSButton *postProcessingEnabledCheckBox;


- (void)projectAdded:(Project *)project;

@end
