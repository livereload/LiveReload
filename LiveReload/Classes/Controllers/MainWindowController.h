
#import <Cocoa/Cocoa.h>
#import "PXListView.h"


@class MAAttachedWindow;
@class StatusItemController;


@interface MainWindowController : NSObject <PXListViewDelegate> {
    NSButton *_startAtLoginCheckbox;
    NSButton *_installSafariExtensionButton;
    NSButton *_installChromeExtensionButton;
    NSButton *_installFirefoxExtensionButton;
    NSTextField *_versionLabel;
    NSTextField *_webSiteLabel;
    NSButton *_backToMainWindowButton;
    NSTextField *_connectionStateLabel;
    BOOL _inSettingsMode;
    NSTextField *_clickToAddFolderLabel;
}


@property(nonatomic, retain) NSWindow *window;

@property(nonatomic, retain) IBOutlet StatusItemController *statusItemController;

@property(nonatomic, retain) IBOutlet NSView *mainView;

@property(nonatomic, retain) IBOutlet NSView *settingsView;

@property(nonatomic, retain) IBOutlet PXListView *listView;

@property(nonatomic, retain) IBOutlet NSButton *addProjectButton;

@property(nonatomic, retain) IBOutlet NSButton *removeProjectButton;
@property (assign) IBOutlet NSTextField *clickToAddFolderLabel;

@property(nonatomic, readonly) BOOL windowVisible;

- (void)toggleMainWindowAtPoint:(NSPoint)pt;

- (void)considerShowingOnAppStartup;
- (void)hideOnAppDeactivation;

- (IBAction)addProjectClicked:(id)sender;
- (IBAction)removeProjectClicked:(id)sender;

- (IBAction)showSettings:(id)sender;
- (IBAction)doneWithSettings:(id)sender;

- (IBAction)quit:(id)sender;

@property (assign) IBOutlet NSButton *startAtLoginCheckbox;
@property (assign) IBOutlet NSButton *installSafariExtensionButton;
@property (assign) IBOutlet NSButton *installChromeExtensionButton;
@property (assign) IBOutlet NSButton *installFirefoxExtensionButton;
@property (assign) IBOutlet NSTextField *versionLabel;
@property (assign) IBOutlet NSTextField *webSiteLabel;
@property (assign) IBOutlet NSButton *backToMainWindowButton;
@property (assign) IBOutlet NSTextField *connectionStateLabel;

@end
