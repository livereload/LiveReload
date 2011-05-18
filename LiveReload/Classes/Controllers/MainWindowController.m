
#import "MainWindowController.h"
#import "MAAttachedWindow.h"
#import "Workspace.h"
#import "ProjectCell.h"
#import "Project.h"


@interface MainWindowController ()

@property(nonatomic) BOOL windowVisible;

- (void)updateButtonsState;

@end


@implementation MainWindowController

@synthesize mainView=_mainView;
@synthesize window=_window;
@synthesize windowVisible=_windowVisible;
@synthesize listView=_listView;
@synthesize addProjectButton=_addProjectButton;
@synthesize removeProjectButton=_removeProjectButton;

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
        [[Workspace sharedWorkspace] addObserver:self forKeyPath:@"projects" options:0 context:nil];
        [self updateButtonsState];
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

- (void)listViewSelectionDidChange:(NSNotification*)aNotification {

}

- (void)updateButtonsState {
    NSUInteger row = self.listView.selectedRow;
    [self.removeProjectButton setEnabled:(row != NSNotFound)];
}

- (IBAction)addProjectClicked:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setPrompt:@"Choose folder"];
    [openPanel setCanChooseFiles:NO];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [openPanel URL];
            NSString *path = [url path];
            Project *project = [[[Project alloc] initWithPath:path] autorelease];
            [[Workspace sharedWorkspace] addProjectsObject:project];
        }
    }];
}

- (IBAction)removeProjectClicked:(id)sender {
    NSUInteger row = self.listView.selectedRow;
    if (row == NSNotFound)
        return;
    Project *project = [[Workspace sharedWorkspace].sortedProjects objectAtIndex:row];
    [[Workspace sharedWorkspace] removeProjectsObject:project];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"projects"]) {
        [self.listView reloadData];
        [self updateButtonsState];
    }
}


@end
