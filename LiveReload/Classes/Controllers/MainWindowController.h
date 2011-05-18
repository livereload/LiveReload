
#import <Cocoa/Cocoa.h>
#import "PXListView.h"


@class MAAttachedWindow;


@interface MainWindowController : NSObject <PXListViewDelegate> {
    NSButton *_startAtLoginCheckbox;
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

@property (assign) IBOutlet NSButton *startAtLoginCheckbox;

@end
