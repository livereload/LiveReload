
#import "MainWindowController.h"
#import "ExtensionsController.h"
#import "CommunicationController.h"

#import "ProjectOptionsSheetController.h"

#import "Workspace.h"
#import "ProjectCell.h"
#import "PXListView+UserInteraction.h"
#import "Project.h"

#import "NSWindowController+TextStyling.h"


@interface MainWindowController () <ProjectCellDelegate, NSWindowDelegate>

- (void)updateMainScreen;
- (void)openEditorForRow:(NSUInteger)rowIndex;

- (void)projectAdded:(Project *)project;

@end


@implementation MainWindowController

@synthesize connectionStateLabel = _connectionStateLabel;

@synthesize listView=_listView;
@synthesize addProjectButton=_addProjectButton;
@synthesize removeProjectButton=_removeProjectButton;
@synthesize clickToAddFolderLabel = _clickToAddFolderLabel;
@synthesize folderListLabel = _folderListLabel;


#pragma mark -

- (id)init {
    self = [super initWithWindowNibName:@"MainWindowController"];
    if (self) {
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}


#pragma mark -

- (void)windowDidLoad {
    [super windowDidLoad];
    [self.window setStyleMask:NSBorderlessWindowMask];
    [self.window setOpaque:NO];
    [self.window setBackgroundColor:[NSColor clearColor]];

    [self.listView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];

    [[Workspace sharedWorkspace] addObserver:self forKeyPath:@"projects" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMainScreen) name:CommunicationStateChangedNotification object:nil];
    [[CommunicationController sharedCommunicationController] addObserver:self forKeyPath:@"numberOfProcessedChanges" options:0 context:nil];

    NSShadow *shadow = [self subtleWhiteShadow];
    NSColor *color = [NSColor colorWithCalibratedRed:63.0/255 green:70.0/255 blue:98.0/255 alpha:1.0];
//    NSColor *linkColor = [NSColor colorWithCalibratedRed:109.0/255 green:118.0/255 blue:149.0/255 alpha:1.0];

    [self styleLabel:_folderListLabel color:color shadow:shadow];
    [self styleLabel:_clickToAddFolderLabel color:color shadow:shadow];
}

- (void)willShow {
    [self.listView reloadData];
    [self updateMainScreen];

    _inProjectEditorMode = NO;
//    if (![[NSUserDefaults standardUserDefaults] boolForKey:PreferencesDoneKey]) {
//        [self showSettings:self];
//    }
}

- (NSUInteger)numberOfRowsInListView:(PXListView*)aListView {
    return [[Workspace sharedWorkspace].sortedProjects count];
}

- (CGFloat)listView:(PXListView*)aListView heightOfRow:(NSUInteger)row {
    return 30;
}

- (PXListViewCell*)listView:(PXListView*)aListView cellForRow:(NSUInteger)row {
    ProjectCell *cell = (ProjectCell *) [aListView dequeueCellWithReusableIdentifier:@"Project"];
    if (cell == nil) {
        cell = [ProjectCell cellLoadedFromNibNamed:@"ProjectCell" reusableIdentifier:@"Project"];
        cell.delegate = self;
    }

    Project *project = [[Workspace sharedWorkspace].sortedProjects objectAtIndex:row];

    [cell.titleLabel setStringValue:project.displayPath];

    return cell;
}

- (void)listView:(PXListView*)aListView rowDoubleClicked:(NSUInteger)rowIndex {
    [self openEditorForRow:rowIndex];
}

- (void)listViewSelectionDidChange:(NSNotification*)aNotification {

}

- (void)updateMainScreen {
    NSUInteger row = self.listView.selectedRow;
    [self.removeProjectButton setEnabled:(row != NSNotFound)];
    [self.clickToAddFolderLabel setHidden:[[Workspace sharedWorkspace].projects count] > 0];

    NSInteger n = [CommunicationController sharedCommunicationController].numberOfSessions;
    if (n == 0 && [[Workspace sharedWorkspace].projects count] == 0) {
        [self.connectionStateLabel setStringValue:@""];
    } else if (n == 0) {
        [self.connectionStateLabel setStringValue:@"Safari: right-click > “Enable LiveReload”. Chrome: click toolbar button."];
    } else if (n == 1) {
        [self.connectionStateLabel setStringValue:[NSString stringWithFormat:@"1 browser connected, %d changes detected so far.", [CommunicationController sharedCommunicationController].numberOfProcessedChanges]];
    } else {
        [self.connectionStateLabel setStringValue:[NSString stringWithFormat:@"%d browsers connected, %d changes detected so far.", n, [CommunicationController sharedCommunicationController].numberOfProcessedChanges]];
    }
    [self styleLabel:self.connectionStateLabel color:[NSColor colorWithCalibratedRed:63.0/255 green:70.0/255 blue:98.0/255 alpha:1.0] shadow:[self subtleWhiteShadow]];
}

- (IBAction)addProjectClicked:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setPrompt:@"Choose folder"];
    [openPanel setCanChooseFiles:NO];
    NSInteger result = [openPanel runModal];
//    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelOKButton) {
        NSURL *url = [openPanel URL];
        NSString *path = [url path];
        Project *project = [[[Project alloc] initWithPath:path memento:nil] autorelease];
        [[Workspace sharedWorkspace] addProjectsObject:project];
        [self performSelector:@selector(projectAdded:) withObject:project afterDelay:0.5];
    }
//    }];
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
        [self updateMainScreen];
    } else if ([keyPath isEqualToString:@"numberOfProcessedChanges"]) {
        [self updateMainScreen];
    }
}


#pragma mark - Drag'n'drop

- (NSArray *)sanitizedPathsFrom:(NSPasteboard *)pboard {
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSString *path in files) {
            BOOL dir;
            if (![fm fileExistsAtPath:path isDirectory:&dir]) {
                return nil;
            } else if (!dir) {
                return nil;
            }
        }
        return files;
    }
    return nil;
}

- (NSDragOperation)listView:(PXListView*)aListView
               validateDrop:(id <NSDraggingInfo>)sender
                proposedRow:(NSUInteger)row
      proposedDropHighlight:(PXListViewDropHighlight)dropHighlight
{
    BOOL genericSupported = (NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric;
    NSArray *files = [self sanitizedPathsFrom:[sender draggingPasteboard]];
    if (genericSupported && [files count] > 0) {
        [aListView setDropRow:row dropHighlight:PXListViewDropBelow];
        return NSDragOperationGeneric;
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)listView:(PXListView*)aListView
      acceptDrop:(id <NSDraggingInfo>)sender
             row:(NSUInteger)row
   dropHighlight:(PXListViewDropHighlight)dropHighlight
{
    BOOL genericSupported = (NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric;
    NSArray *pathes = [self sanitizedPathsFrom:[sender draggingPasteboard]];
    if (genericSupported && [pathes count] > 0) {
        for (NSString *path in pathes) {
            Project *newProject = [[[Project alloc] initWithPath:path memento:nil] autorelease];
            [[Workspace sharedWorkspace] addProjectsObject:newProject];
            if ([pathes count] == 1) {
                [self projectAdded:newProject];
            }
        }
        return YES;
    } else {
        return NO;
    }
}


#pragma mark -

- (void)projectAdded:(Project *)project {
    NSInteger index = [[Workspace sharedWorkspace].sortedProjects indexOfObject:project];
    if (index == NSNotFound)
        return;
    [self openEditorForRow:index];
}


#pragma mark - Project options

- (void)openEditorForRow:(NSUInteger)rowIndex {
    Project *project = [[Workspace sharedWorkspace].sortedProjects objectAtIndex:rowIndex];
    projectEditorController = [[ProjectOptionsSheetController alloc] initWithProject:project];
    NSWindow *sheet = [projectEditorController window];
    _sheetRow = rowIndex;
    _inProjectEditorMode = YES;
    [self.window setLevel:NSFloatingWindowLevel];
    //[sheet makeKeyWindow];
    [NSApp beginSheet:sheet
       modalForWindow:self.window
        modalDelegate:self
       didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
          contextInfo:nil];
}

- (void)checkboxClickedForLanguage:(NSString *)language inCell:(ProjectCell *)cell {
    if ([cell.compileCoffeeScriptCheckbox state] == NSOnState) {
    }
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    _inProjectEditorMode = NO;
    [self.window setLevel:NSNormalWindowLevel];
    [projectEditorController release], projectEditorController = nil;

    // at least on OS X 10.6, the window position is only persisted on quit
    [[NSUserDefaults standardUserDefaults] performSelector:@selector(synchronize) withObject:nil afterDelay:2.0];
}

- (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet usingRect:(NSRect)rect {
    NSView *cell = [_listView cellForRowAtIndex:_sheetRow];
    NSRect frame = [cell frame];
    frame = [[cell superview] convertRect:frame toView:self.window.contentView];
    frame.size.height = 0;
    return frame;
}


@end
