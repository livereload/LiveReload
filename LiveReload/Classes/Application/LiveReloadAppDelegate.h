
#import <Cocoa/Cocoa.h>

@class StatusItemController;

@interface LiveReloadAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;
@property(nonatomic, retain, readonly) StatusItemController *statusItemController;

@end
