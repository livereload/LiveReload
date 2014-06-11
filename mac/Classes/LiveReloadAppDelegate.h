
#import <Cocoa/Cocoa.h>

#import "NodeAppDelegate.h"


@class AppState;
@class StatusItemController;
@class NewMainWindowController;

@interface LiveReloadAppDelegate : NodeAppDelegate <NSApplicationDelegate>

@property(nonatomic, strong) StatusItemController *statusItemController;
@property(nonatomic, strong) NewMainWindowController *mainWindowController;
@property(nonatomic, readonly) int port;

- (IBAction)displayMainWindow:sender;
- (IBAction)toggleMainWindow:sender;

- (void)addProjectsAtPaths:(NSArray *)paths;
- (void)addProjectAtPath:(NSString *)path;

// help and support
- (IBAction)openSupport:(id)sender;
- (IBAction)openHelp:(id)sender;


@end
