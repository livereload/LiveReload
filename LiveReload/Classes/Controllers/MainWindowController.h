
#import <Cocoa/Cocoa.h>
#import "PXListView.h"


@class MAAttachedWindow;


@interface MainWindowController : NSObject <PXListViewDelegate>

@property(nonatomic, retain) NSWindow *window;

@property(nonatomic, retain) IBOutlet NSView *mainView;

@property(nonatomic, retain) IBOutlet PXListView *listView;

@property(nonatomic, readonly) BOOL windowVisible;

- (void)toggleMainWindowAtPoint:(NSPoint)pt;

- (void)hideOnAppDeactivation;

@end
