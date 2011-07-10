
#import "StatusItemController.h"
#import "MainWindowController.h"
#import "StatusItemView.h"
#import "Workspace.h"
#import "Project.h"


@interface StatusItemController () <StatusItemViewDelegate>

@property(nonatomic, retain) NSStatusItem *statusItem;
@property(nonatomic, retain) StatusItemView *statusItemView;

- (void)updateStatusIconState;

@end


@implementation StatusItemController

@synthesize statusItem=_statusItem;
@synthesize statusItemView=_statusItemView;
@synthesize mainWindowController=_mainWindowController;

- (void)showStatusBarIcon {
    float width = 25.0;
    float height = [[NSStatusBar systemStatusBar] thickness];
    NSRect viewFrame = NSMakeRect(0, 0, width, height);

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:width];
    self.statusItemView = [[[StatusItemView alloc] initWithFrame:viewFrame] autorelease];
    self.statusItemView.delegate = self;
    [self.statusItem setView:self.statusItemView];

    [self.mainWindowController addObserver:self forKeyPath:@"windowVisible" options:0 context:nil];
    [[Workspace sharedWorkspace] addObserver:self forKeyPath:@"monitoringEnabled" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDetectChange) name:ProjectDidDetectChangeNotification object:nil];

    [self updateStatusIconState];
}

- (NSPoint)statusItemPosition {
    NSRect frame = [[self.statusItemView window] frame];
    return NSMakePoint(NSMidX(frame), NSMinY(frame));
}

- (void)updateStatusIconState {
    self.statusItemView.selected = self.mainWindowController.windowVisible;
    self.statusItemView.active = [Workspace sharedWorkspace].monitoringEnabled;
}

- (void)didDetectChange {
    [self.statusItemView blink];
}


#pragma mark -
#pragma mark StatusItemViewDelegate methods

- (void)statusItemView:(StatusItemView *)view clickedAtPoint:(NSPoint)pt {
    [self.mainWindowController toggleMainWindow];
}

- (void)statusItemView:(StatusItemView *)view acceptedDroppedDirectories:(NSArray *)pathes {
    for (NSString *path in pathes) {
        [[Workspace sharedWorkspace] addProjectsObject:[[[Project alloc] initWithPath:path memento:nil] autorelease]];
    }
    [self.mainWindowController showMainWindow];
}


#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"windowVisible"]) {
        [self updateStatusIconState];
    } else if ([keyPath isEqualToString:@"monitoringEnabled"]) {
        [self updateStatusIconState];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
