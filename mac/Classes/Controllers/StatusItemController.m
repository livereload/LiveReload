
#import "LiveReloadAppDelegate.h"

#import "StatusItemController.h"
#import "StatusItemView.h"
#import "Workspace.h"
#import "Project.h"
#import "DockIcon.h"


@interface StatusItemController () <StatusItemViewDelegate>

@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) StatusItemView *statusItemView;

- (void)updateStatusIconState;
- (void)updateStatusIconVisibility;

@end


@implementation StatusItemController

@synthesize statusItem=_statusItem;
@synthesize statusItemView=_statusItemView;
@synthesize mainWindowController=_mainWindowController;

- (void)initStatusBarIcon {
    [[Workspace sharedWorkspace] addObserver:self forKeyPath:@"monitoringEnabled" options:0 context:nil];
    [[DockIcon currentDockIcon] addObserver:self forKeyPath:@"menuBarIconVisible" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDetectChange) name:ProjectDidDetectChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willBeginCompilation) name:ProjectWillBeginCompilationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEndCompilation) name:ProjectDidEndCompilationNotification object:nil];

    [self updateStatusIconVisibility];
}


#pragma mark - Visibility

- (void)showStatusBarIcon {
    float width = 24.0;
    float height = [[NSStatusBar systemStatusBar] thickness];
    NSRect viewFrame = NSMakeRect(0, 0, width, height);
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:width];
    self.statusItemView = [[StatusItemView alloc] initWithFrame:viewFrame];
    self.statusItemView.delegate = self;
    [self.statusItem setView:self.statusItemView];

    [self updateStatusIconState];
}

- (void)hideStatusBarIcon {
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    self.statusItemView.delegate = nil;
    self.statusItemView = nil;
    self.statusItem = nil;
}

- (void)updateStatusIconVisibility {
    BOOL shouldBeVisible = [DockIcon currentDockIcon].menuBarIconVisible;
    if (shouldBeVisible != (self.statusItem != nil)) {
        if (shouldBeVisible) {
            [self showStatusBarIcon];
        } else {
            [self hideStatusBarIcon];
        }
    }
}


#pragma mark - Public methods

- (NSPoint)statusItemPosition {
    NSRect frame = [[self.statusItemView window] frame];
    return NSMakePoint(NSMidX(frame), NSMinY(frame));
}

- (void)updateStatusIconState {
    self.statusItemView.active = [Workspace sharedWorkspace].monitoringEnabled;
}

- (void)didDetectChange {
    [[DockIcon currentDockIcon] showMenuBarIconForDuration:0.5];
    [self.statusItemView animateOnce];
}

- (void)willBeginCompilation {
    [[DockIcon currentDockIcon] setMenuBarIconVisibility:YES forRequestKey:@"compilation"];
    [self.statusItemView startAnimation];
}

- (void)didEndCompilation {
    [self.statusItemView endAnimation];
    [[DockIcon currentDockIcon] setMenuBarIconVisibility:NO forRequestKey:@"compilation" gracePeriod:0.5];
}


#pragma mark -
#pragma mark StatusItemViewDelegate methods

- (void)statusItemViewClicked:(StatusItemView *)view {
    [[NSApp delegate] performSelector:@selector(toggleMainWindow:) withObject:nil afterDelay:0.01];
}

- (void)statusItemView:(StatusItemView *)view acceptedDroppedDirectories:(NSArray *)pathes {
    [[NSApp delegate] addProjectsAtPaths:pathes];
}


#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"monitoringEnabled"]) {
        [self updateStatusIconState];
    } else if ([keyPath isEqualToString:@"menuBarIconVisible"]) {
        [self updateStatusIconVisibility];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
