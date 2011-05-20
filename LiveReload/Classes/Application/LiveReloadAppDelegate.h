
#import <Cocoa/Cocoa.h>

@class StatusItemController;
@class MainWindowController;

@interface LiveReloadAppDelegate : NSObject <NSApplicationDelegate> {
    StatusItemController *_statusItemController;
    MainWindowController *_mainWindowController;
}

@property(nonatomic, retain) IBOutlet StatusItemController *statusItemController;
@property(nonatomic, retain) IBOutlet MainWindowController *mainWindowController;

@end
