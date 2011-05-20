
#import "StatusItemController.h"
#import "MainWindowController.h"
#import "StatusItemView.h"


@interface StatusItemController () <StatusItemViewDelegate>

@property(nonatomic, retain) NSStatusItem *statusItem;
@property(nonatomic, retain) StatusItemView *statusItemView;

@end


@implementation StatusItemController

@synthesize statusItem=_statusItem;
@synthesize statusItemView=_statusItemView;
@synthesize mainWindowController=_mainWindowController;

- (void)showStatusBarIcon {
    float width = 30.0;
    float height = [[NSStatusBar systemStatusBar] thickness];
    NSRect viewFrame = NSMakeRect(0, 0, width, height);

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:width];
    self.statusItemView = [[[StatusItemView alloc] initWithFrame:viewFrame] autorelease];
    self.statusItemView.delegate = self;
    [self.statusItem setView:self.statusItemView];

    [self.mainWindowController addObserver:self forKeyPath:@"windowVisible" options:0 context:nil];
}

- (CGPoint)statusItemPosition {
    CGRect frame = [[self.statusItemView window] frame];
    return CGPointMake(CGRectGetMidX(frame), CGRectGetMinY(frame));
}


#pragma mark -
#pragma mark StatusItemViewDelegate methods

- (void)statusItemView:(StatusItemView *)view clickedAtPoint:(NSPoint)pt {
    [self.mainWindowController toggleMainWindowAtPoint:pt];
}


#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"windowVisible"]) {
        self.statusItemView.selected = self.mainWindowController.windowVisible;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
