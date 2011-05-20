
#import <Cocoa/Cocoa.h>
#import "PXListView.h"


@class MAAttachedWindow;


@interface MainWindowController : NSObject <PXListViewDelegate> {
    NSButton *_startAtLoginCheckbox;
    NSButton *_installSafariExtensionButton;
    NSButton *_installChromeExtensionButton;
    NSButton *_installFirefoxExtensionButton;
}


@property(nonatomic, retain) NSWindow *window;

@property(nonatomic, retain) IBOutlet NSView *mainView;

@property(nonatomic, retain) IBOutlet NSView *settingsView;

@property(nonatomic, retain) IBOutlet PXListView *listView;

@property(nonatomic, retain) IBOutlet NSButton *addProjectButton;

@property(nonatomic, retain) IBOutlet NSButton *removeProjectButton;

@property(nonatomic, readonly) BOOL windowVisible;

- (void)toggleMainWindowAtPoint:(NSPoint)pt;

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

@end
