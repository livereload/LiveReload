
#import <Cocoa/Cocoa.h>


@class Project;
@class TerminalViewController;


@interface NewMainWindowController : NSWindowController {
    NSObject              *_projectsItem;
    NSImage               *_folderImage;

    NSArray               *_projects;
    Project               *_selectedProject;

    NSArray               *_panes;
    NSInteger              _currentPane;

    NSWindowController    *_projectSettingsSheetController;

    TerminalViewController *_terminalViewController;

    IBOutlet NSMenuItem *_showInDockMenuItem;
    IBOutlet NSMenuItem *_showInMenuBarMenuItem;
    IBOutlet NSMenuItem *_showNowhereMenuItem;

    IBOutlet NSMenuItem *licenseStatusMenuItem;
    IBOutlet NSPopUpButton *purchasePopUpButton;
    IBOutlet NSMenuItem *displayLicenseManagerMenuItem;
    IBOutlet NSMenuItem *displayLicenseManagerMenuItemSeparator;

    IBOutlet NSMenuItem *checkForUpdatesMenuItem;
    IBOutlet NSMenuItem *checkForUpdatesMenuItemSeparator;

    IBOutlet NSTextField *urlsTextField;

    IBOutlet NSPopUpButton *customScriptPopUp;
    NSMutableArray *_userScripts;
    NSUInteger _firstUserScriptIndex;
}

@property (weak) IBOutlet NSView *titleBarSideView;
@property (weak) IBOutlet NSMenuItem *versionMenuItem;
@property (weak) IBOutlet NSMenuItem *openAtLoginMenuItem;

@property (weak) IBOutlet NSOutlineView *projectOutlineView;
@property (weak) IBOutlet NSButton *addProjectButton;
@property (weak) IBOutlet NSButton *removeProjectButton;
@property (weak) IBOutlet NSView *gettingStartedView;
@property (weak) IBOutlet NSImageView *gettingStartedIconView;
@property (weak) IBOutlet NSTextField *gettingStartedLabelField;

@property (weak) IBOutlet NSTextField *statusTextField;
@property (weak) IBOutlet NSButton *terminalButton;

@property (weak) IBOutlet NSBox *paneBorderBox;
@property (weak) IBOutlet NSView *panePlaceholder;

// welcome pane
@property (weak) IBOutlet NSView *welcomePane;
@property (weak) IBOutlet NSTextField *welcomeMessageField;

// project pane
@property (weak) IBOutlet NSView *projectPane;
@property (weak) IBOutlet NSImageView *iconView;
@property (weak) IBOutlet NSTextField *nameTextField;
@property (weak) IBOutlet NSTextField *pathTextField;
@property (weak) IBOutlet NSTextField *snippetLabelField;
@property (weak) IBOutlet NSTextField *snippetBodyTextField;
@property (weak) IBOutlet NSTextField *monitoringSummaryLabelField;
@property (weak) IBOutlet NSButton *compilerEnabledCheckBox;
@property (weak) IBOutlet NSButton *postProcessingEnabledCheckBox;
@property (weak) IBOutlet NSTextField *availableCompilersLabel;


- (void)projectAdded:(Project *)project;


- (IBAction)toggleVisibilityMode:(NSMenuItem *)sender;

- (IBAction)doNothingOnShowAs:(id)sender;

@end
