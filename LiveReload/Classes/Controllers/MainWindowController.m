
#import "MainWindowController.h"
#import "ExtensionsController.h"
#import "StatusItemController.h"
#import "CommunicationController.h"

#import "MAAttachedWindow.h"
#import "Workspace.h"
#import "ProjectCell.h"
#import "Project.h"


#define PreferencesDoneKey @"PreferencesDone"


@interface MainWindowController ()

@property(nonatomic) BOOL windowVisible;

- (void)updateMainScreen;
- (void)updateSettingsScreen;

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
    [[Workspace sharedWorkspace] addObserver:self forKeyPath:@"projects" options:0 context:nil];

    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [self.versionLabel setStringValue:[NSString stringWithFormat:@"v%@", version]];

    // both are needed, otherwise hyperlink won't accept mousedown
    [self.webSiteLabel setAllowsEditingTextAttributes:YES];
    [self.webSiteLabel setSelectable:YES];

    [self.webSiteLabel setAttributedStringValue:[[[NSAttributedString alloc] initWithString:[self.webSiteLabel stringValue] attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor colorWithCalibratedRed:0.7 green:0.7 blue:1.0 alpha:1.0], NSForegroundColorAttributeName, [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, [NSURL URLWithString:[self.webSiteLabel stringValue]], NSLinkAttributeName, [NSFont systemFontOfSize:13], NSFontAttributeName, nil]] autorelease]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMainScreen) name:CommunicationStateChangedNotification object:nil];

    [[CommunicationController sharedCommunicationController] addObserver:self forKeyPath:@"numberOfProcessedChanges" options:0 context:nil];
}

- (void)considerShowingOnAppStartup {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:PreferencesDoneKey]) {
        [self toggleMainWindowAtPoint:self.statusItemController.statusItemPosition];
    }
}

- (void)toggleMainWindowAtPoint:(NSPoint)pt {
    [NSApp activateIgnoringOtherApps:YES];
    if (!self.window) {
        _window = [[MAAttachedWindow alloc] initWithView:self.mainView
                                         attachedToPoint:pt
                                                inWindow:nil
                                                  onSide:MAPositionBottom
                                              atDistance:0.0];
        [self.listView reloadData];
        [self updateMainScreen];

        _inSettingsMode = NO;
        if (![[NSUserDefaults standardUserDefaults] boolForKey:PreferencesDoneKey]) {
            [self showSettings:self];
        }

        [self.window makeKeyAndOrderFront:self];
        self.windowVisible = YES;
    } else {
        [self.window orderOut:self];
        self.window = nil;
        self.windowVisible = NO;
    }
}

- (void)hideOnAppDeactivation {
    if (_inSettingsMode)
        return;
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

@end
