
#import <Cocoa/Cocoa.h>

@class StatusItemController;
@class MainWindowController;
@class PreferencesWindowController;

@interface LiveReloadAppDelegate : NSObject <NSApplicationDelegate> {
    StatusItemController  *_statusItemController;
    MainWindowController  *_mainWindowController;
    PreferencesWindowController *_preferencesWindowController;
}

@property(nonatomic, retain) StatusItemController *statusItemController;
@property(nonatomic, retain) MainWindowController *mainWindowController;
@property(nonatomic, retain) PreferencesWindowController *preferencesWindowController;

@property(nonatomic, getter=isWindowVisible, readonly) BOOL windowVisible;
- (IBAction)toggleWindow:sender;
- (IBAction)displayWindow:sender;
- (IBAction)hideWindow:sender;
- (IBAction)displayMainWindow:sender;
- (IBAction)displayPreferencesWindow:sender;

@end
