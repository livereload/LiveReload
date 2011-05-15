
#import "MainWindowController.h"
#import "MAAttachedWindow.h"
#import "Workspace.h"
#import "ProjectCell.h"
#import "Project.h"


@interface MainWindowController ()

@property(nonatomic) BOOL windowVisible;

@end


@implementation MainWindowController

@synthesize mainView=_mainView;
@synthesize window=_window;
@synthesize windowVisible=_windowVisible;
@synthesize listView=_listView;

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
        [self.listView reloadData];
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

- (NSUInteger)numberOfRowsInListView:(PXListView*)aListView {
    return [[Workspace sharedWorkspace].sortedProjects count];
}

- (CGFloat)listView:(PXListView*)aListView heightOfRow:(NSUInteger)row {
    return 57;
}

- (PXListViewCell*)listView:(PXListView*)aListView cellForRow:(NSUInteger)row {
    ProjectCell *cell = (ProjectCell *) [aListView dequeueCellWithReusableIdentifier:@"Project"];
    if (cell == nil) {
        cell = [ProjectCell cellLoadedFromNibNamed:@"ProjectCell" reusableIdentifier:@"Project"];
    }

    Project *project = [[Workspace sharedWorkspace].sortedProjects objectAtIndex:row];

    [cell.titleLabel setStringValue:project.path];

    return cell;
}

@end
