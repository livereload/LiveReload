
#import <Cocoa/Cocoa.h>

@class StatusItemController;
@class NewMainWindowController;

@interface LiveReloadAppDelegate : NSObject <NSApplicationDelegate> {
    StatusItemController  *_statusItemController;
    NewMainWindowController  *_mainWindowController;
}

@property(nonatomic, retain) StatusItemController *statusItemController;
@property(nonatomic, retain) NewMainWindowController *mainWindowController;

- (IBAction)displayMainWindow:sender;
- (IBAction)toggleMainWindow:sender;

- (void)addProjectsAtPaths:(NSArray *)paths;
- (void)addProjectAtPath:(NSString *)path;

// help and support
- (IBAction)openSupport:(id)sender;
- (IBAction)openHelp:(id)sender;


@end
