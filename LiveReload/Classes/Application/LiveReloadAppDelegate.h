
#import <Cocoa/Cocoa.h>

@class StatusItemController;
@class NewMainWindowController;
@class PreferencesWindowController;

@interface LiveReloadAppDelegate : NSObject <NSApplicationDelegate> {
    StatusItemController  *_statusItemController;
    NewMainWindowController  *_mainWindowController;
    PreferencesWindowController *_preferencesWindowController;
}

@property(nonatomic, retain) StatusItemController *statusItemController;
@property(nonatomic, retain) NewMainWindowController *mainWindowController;
@property(nonatomic, retain) PreferencesWindowController *preferencesWindowController;

- (IBAction)displayMainWindow:sender;
- (IBAction)displayPreferencesWindow:sender;
- (IBAction)toggleMainWindow:sender;

- (void)addProjectsAtPaths:(NSArray *)paths;

@end
