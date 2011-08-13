
#import "LiveReloadAppDelegate.h"

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
    float width = 24.0;
    float height = [[NSStatusBar systemStatusBar] thickness];
    NSRect viewFrame = NSMakeRect(0, 0, width, height);

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:width];
    self.statusItemView = [[[StatusItemView alloc] initWithFrame:viewFrame] autorelease];
    self.statusItemView.delegate = self;
    [self.statusItem setView:self.statusItemView];

    [[NSApp delegate] addObserver:self forKeyPath:@"windowVisible" options:0 context:nil];
    [[Workspace sharedWorkspace] addObserver:self forKeyPath:@"monitoringEnabled" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDetectChange) name:ProjectDidDetectChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willBeginCompilation) name:ProjectWillBeginCompilationNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEndCompilation) name:ProjectDidEndCompilationNotification object:nil];

    [self updateStatusIconState];
}

- (NSPoint)statusItemPosition {
    NSRect frame = [[self.statusItemView window] frame];
    return NSMakePoint(NSMidX(frame), NSMinY(frame));
}

- (void)updateStatusIconState {
    self.statusItemView.selected = [[NSApp delegate] isWindowVisible];
    self.statusItemView.active = [Workspace sharedWorkspace].monitoringEnabled;
}

- (void)didDetectChange {
    [self.statusItemView animateOnce];
}

- (void)willBeginCompilation {
    [self.statusItemView startAnimation];
}

- (void)didEndCompilation {
    [self.statusItemView endAnimation];
}


#pragma mark -
#pragma mark StatusItemViewDelegate methods

- (void)statusItemView:(StatusItemView *)view clickedAtPoint:(NSPoint)pt {
    [[NSApp delegate] toggleWindow:nil];
}

- (void)statusItemView:(StatusItemView *)view acceptedDroppedDirectories:(NSArray *)pathes {
    Project *newProject = nil;
    for (NSString *path in pathes) {
        newProject = [[[Project alloc] initWithPath:path memento:nil] autorelease];
        [[Workspace sharedWorkspace] addProjectsObject:newProject];
    }
    [[NSApp delegate] displayMainWindow:nil];
    if ([pathes count] == 1) {
        [self.mainWindowController projectAdded:newProject];
    }
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
