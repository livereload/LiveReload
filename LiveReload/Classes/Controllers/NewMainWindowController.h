
#import <Cocoa/Cocoa.h>


@class Project;


@interface NewMainWindowController : NSWindowController {
    NSObject              *_projectsItem;
    NSImage               *_folderImage;

    NSArray               *_projects;
    Project               *_selectedProject;

    NSArray               *_panes;
    NSInteger              _currentPane;

    NSWindowController    *_projectSettingsSheetController;
}

@property (assign) IBOutlet NSOutlineView *projectOutlineView;
@property (assign) IBOutlet NSButton *addProjectButton;
@property (assign) IBOutlet NSButton *removeProjectButton;
@property (assign) IBOutlet NSView *gettingStartedView;
@property (assign) IBOutlet NSImageView *gettingStartedIconView;
@property (assign) IBOutlet NSTextField *gettingStartedLabelField;

@property (assign) IBOutlet NSTextField *statusTextField;

@property (assign) IBOutlet NSBox *paneBorderBox;
@property (assign) IBOutlet NSView *panePlaceholder;

// welcome pane
@property (assign) IBOutlet NSView *welcomePane;
@property (assign) IBOutlet NSTextField *welcomeMessageField;

// project pane
@property (assign) IBOutlet NSView *projectPane;
@property (assign) IBOutlet NSImageView *iconView;
@property (assign) IBOutlet NSTextField *nameTextField;
@property (assign) IBOutlet NSTextField *pathTextField;
@property (assign) IBOutlet NSTextField *snippetLabelField;
@property (assign) IBOutlet NSButton *compilerEnabledCheckBox;
@property (assign) IBOutlet NSButton *postProcessingEnabledCheckBox;
@property (assign) IBOutlet NSTextField *availableCompilersLabel;


- (void)projectAdded:(Project *)project;


- (IBAction)showPostProcessingOptions:(id)sender;

@end
