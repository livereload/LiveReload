
#import "MainWindowController.h"
#import "MAAttachedWindow.h"


@interface MainWindowController ()

@property(nonatomic) BOOL windowVisible;

@end


@implementation MainWindowController

@synthesize mainView=_mainView;
@synthesize window=_window;
@synthesize windowVisible=_windowVisible;

- (void)toggleMainWindowAtPoint:(NSPoint)pt {
    [NSApp activateIgnoringOtherApps:YES];
    if (!self.window) {
        _window = [[MAAttachedWindow alloc] initWithView:self.mainView
                                         attachedToPoint:pt
                                                inWindow:nil
                                                  onSide:MAPositionBottom
                                              atDistance:0.0];
        [self.window makeKeyAndOrderFront:self];
        self.windowVisible = YES;
    } else {
        [self.window orderOut:self];
        self.window = nil;
        self.windowVisible = NO;
    }
}

- (void)hideOnAppDeactivation {
    [self.window orderOut:self];
    self.window = nil;
    self.windowVisible = NO;
}

@end
