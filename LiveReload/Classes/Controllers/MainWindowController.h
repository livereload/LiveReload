
#import <Cocoa/Cocoa.h>


@class MAAttachedWindow;


@interface MainWindowController : NSObject

@property(nonatomic, retain) NSWindow *window;

@property(nonatomic, retain) IBOutlet NSView *mainView;

@property(nonatomic, readonly) BOOL windowVisible;

- (void)toggleMainWindowAtPoint:(NSPoint)pt;

- (void)hideOnAppDeactivation;

@end
