
#import <Cocoa/Cocoa.h>

@class MainWindowController;

@interface StatusItemController : NSObject {
    NSStatusItem *_statusItem;
}

@property(nonatomic, retain) IBOutlet MainWindowController *mainWindowController;

- (void)showStatusBarIcon;

@property(nonatomic, readonly) CGPoint statusItemPosition;

@end
