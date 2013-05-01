
#import <Cocoa/Cocoa.h>

#import "NodeAppDelegate.h"


@class StatusItemController;
@class NewMainWindowController;

@interface LiveReloadAppDelegate : NodeAppDelegate <NSApplicationDelegate> {
    StatusItemController  *_statusItemController;
    NewMainWindowController  *_mainWindowController;
    int _port;
}

@property(nonatomic, retain) StatusItemController *statusItemController;
@property(nonatomic, retain) NewMainWindowController *mainWindowController;
@property(nonatomic, readonly) int port;

- (IBAction)displayMainWindow:sender;
- (IBAction)toggleMainWindow:sender;

- (void)addProjectsAtPaths:(NSArray *)paths;
- (void)addProjectAtPath:(NSString *)path;

// help and support
- (IBAction)openSupport:(id)sender;
- (IBAction)openHelp:(id)sender;


@end
