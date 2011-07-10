
#import "MainWindowController.h"
#import "ExtensionsController.h"
#import "StatusItemController.h"
#import "CommunicationController.h"

#import "ProjectOptionsSheetController.h"

#import "MAAttachedWindow.h"
#import "Workspace.h"
#import "ProjectCell.h"
#import "PXListView+UserInteraction.h"
#import "Project.h"


#define PreferencesDoneKey @"PreferencesDone"


@interface MainWindowController () <ProjectCellDelegate, NSWindowDelegate>

@property(nonatomic) BOOL windowVisible;

- (void)updateMainScreen;
- (void)updateSettingsScreen;
- (void)openEditorForRow:(NSUInteger)rowIndex;

@end


@implementation MainWindowController

@synthesize startAtLoginCheckbox = _startAtLoginCheckbox;
@synthesize installSafariExtensionButton = _installSafariExtensionButton;
@synthesize installChromeExtensionButton = _installChromeExtensionButton;
@synthesize installFirefoxExtensionButton = _installFirefoxExtensionButton;
@synthesize versionLabel = _versionLabel;
@synthesize webSiteLabel = _webSiteLabel;
@synthesize backToMainWindowButton = _backToMainWindowButton;
@synthesize connectionStateLabel = _connectionStateLabel;

@synthesize mainView=_mainView;
@synthesize settingsView=_settingsView;

@synthesize statusItemController=_statusItemController;
@synthesize window=_window;
@synthesize windowVisible=_windowVisible;
@synthesize listView=_listView;
@synthesize addProjectButton=_addProjectButton;
@synthesize removeProjectButton=_removeProjectButton;
@synthesize clickToAddFolderLabel = _clickToAddFolderLabel;

- (void)awakeFromNib {
    [self.startAtLoginCheckbox setAttributedTitle:[[[NSAttributedString alloc] initWithString:[self.startAtLoginCheckbox title] attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor],NSForegroundColorAttributeName, [NSFont systemFontOfSize:13], NSFontAttributeName, nil]] autorelease]];

    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [self.versionLabel setStringValue:[NSString stringWithFormat:@"v%@", version]];

    // both are needed, otherwise hyperlink won't accept mousedown
    [self.webSiteLabel setAllowsEditingTextAttributes:YES];
    [self.webSiteLabel setSelectable:YES];

    [self.webSiteLabel setAttributedStringValue:[[[NSAttributedString alloc] initWithString:[self.webSiteLabel stringValue] attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor colorWithCalibratedRed:0.7 green:0.7 blue:1.0 alpha:1.0], NSForegroundColorAttributeName, [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, [NSURL URLWithString:[self.webSiteLabel stringValue]], NSLinkAttributeName, [NSFont systemFontOfSize:13], NSFontAttributeName, nil]] autorelease]];
}

- (void)startUp {
    [[Workspace sharedWorkspace] addObserver:self forKeyPath:@"projects" options:0 context:nil];

    [self.listView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMainScreen) name:CommunicationStateChangedNotification object:nil];

    [[CommunicationController sharedCommunicationController] addObserver:self forKeyPath:@"numberOfProcessedChanges" options:0 context:nil];
}

- (void)considerShowingOnAppStartup {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:PreferencesDoneKey]) {
        [self showMainWindow];
    }
}

- (void)showMainWindow {
    if (self.window)
        return;
    [NSApp activateIgnoringOtherApps:YES];
    _window = [[MAAttachedWindow alloc] initWithView:self.mainView
                                     attachedToPoint:self.statusItemController.statusItemPosition
                                            inWindow:nil
                                              onSide:MAPositionBottom
                                          atDistance:0.0];
    [_window setDelegate:self];
    [self.listView reloadData];
    [self updateMainScreen];

    _inSettingsMode = NO;
    _inProjectEditorMode = NO;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:PreferencesDoneKey]) {
        [self showSettings:self];
    }

    [self.window makeKeyAndOrderFront:self];
    self.windowVisible = YES;
}

- (void)toggleMainWindow {
    if (!self.window) {
        [self showMainWindow];
    } else {
        [self.window orderOut:self];
        self.window = nil;
        self.windowVisible = NO;
    }
}

- (void)hideOnAppDeactivation {
    if (_inSettingsMode || _inProjectEditorMode)
        return;
    [self.window orderOut:self];
    self.window = nil;
    self.windowVisible = NO;
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
            Project *project = [[[Project alloc] initWithPath:path memento:nil] autorelease];
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

- (IBAction)showSettings:(id)sender {
    _inSettingsMode = YES;
    [self.window setLevel:NSFloatingWindowLevel];

    [self.backToMainWindowButton setTitle:([[NSUserDefaults standardUserDefaults] boolForKey:PreferencesDoneKey] ? @"Back to LiveReload" : @"Start using LiveReload")];

    [self updateSettingsScreen];
    self.settingsView.frame = self.mainView.frame;
    [[self.mainView superview] addSubview:self.settingsView];
    [self.mainView removeFromSuperview];
}

- (IBAction)doneWithSettings:(id)sender {
    _inSettingsMode = NO;
    [self.window setLevel:NSNormalWindowLevel];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:PreferencesDoneKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[self.settingsView superview] addSubview:self.mainView];
    [self.settingsView removeFromSuperview];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"projects"]) {
        [self.listView reloadData];
        [self updateMainScreen];
    } else if ([keyPath isEqualToString:@"numberOfProcessedChanges"]) {
        [self updateMainScreen];
    }
}

- (void)updateSettingsScreen {
    ExtensionsController *extensionsController = [ExtensionsController sharedExtensionsController];

    NSInteger safariVersion = extensionsController.versionOfInstalledSafariExtension;
    if (safariVersion == 0) {
        [self.installSafariExtensionButton setTitle:@"Install"];
        [self.installSafariExtensionButton setEnabled:YES];
    } else if (safariVersion < extensionsController.latestSafariExtensionVersion) {
        [self.installSafariExtensionButton setTitle:@"Update"];
        [self.installSafariExtensionButton setEnabled:YES];
    } else {
        [self.installSafariExtensionButton setTitle:@"Installed"];
        [self.installSafariExtensionButton setEnabled:NO];
    }

    NSInteger chromeVersion = extensionsController.versionOfInstalledChromeExtension;
    if (chromeVersion == 0) {
        [self.installChromeExtensionButton setTitle:@"Install"];
        [self.installChromeExtensionButton setEnabled:YES];
    } else if (chromeVersion < extensionsController.latestChromeExtensionVersion) {
        [self.installChromeExtensionButton setTitle:@"Update"];
        [self.installChromeExtensionButton setEnabled:YES];
    } else {
        [self.installChromeExtensionButton setTitle:@"Installed"];
        [self.installChromeExtensionButton setEnabled:NO];
    }
}

- (IBAction)quit:(id)sender {
    [NSApp terminate:sender];
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
            [[Workspace sharedWorkspace] addProjectsObject:[[[Project alloc] initWithPath:path memento:nil] autorelease]];
        }
        return YES;
    } else {
        return NO;
    }
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
       modalForWindow:_window
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
    frame = [[cell superview] convertRect:frame toView:_mainView];
    frame.size.height = 0;
    return frame;
}


@end
