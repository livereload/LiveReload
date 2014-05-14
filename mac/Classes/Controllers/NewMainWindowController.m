
#import "NewMainWindowController.h"

#import "MonitoringSettingsWindowController.h"
#import "TerminalViewController.h"
#import "LicenseCodeWindowController.h"
#import "PreferencesController.h"
#import "AppState.h"

#import "LiveReloadAppDelegate.h"
#import "PluginManager.h"
#import "Compiler.h"

#import "ImageAndTextCell.h"

#import "Workspace.h"
#import "Project.h"
#import "Preferences.h"
#import "UserScript.h"

#import "Stats.h"
#import "ShitHappens.h"
#import "ATLoginItemController.h"
#import "DockIcon.h"
#import "LicenseManager.h"
#import "ATAutolayout.h"
#import "ATStackView.h"
#import "Action.h"
#import "ActionListView.h"
#import "ATSolidView.h"
#import "ATFlippedView.h"
#import "ATAttributedStringAdditions.h"
#import "ATObservation.h"

#import "jansson.h"


typedef enum {
    PaneWelcome,
    PaneProject,
} Pane;
enum { PANE_COUNT = PaneProject+1 };


@interface NewMainWindowController () <NSAnimationDelegate, NSTextFieldDelegate>

+ (NewMainWindowController *)sharedMainWindowController;

- (void)updatePanes;
- (void)updateProjectList;
- (void)restoreSelection;
- (void)selectedProjectDidChange;

- (void)showProjectSettingsSheet:(Class)klass;

- (void)updateStatus;

- (void)updateItemStates;

- (void)updateLicensingUI;
- (void)updateURLs;

@property (strong) NSNib *actionsRowNib;
@property (weak) IBOutlet ActionListView *actionsStackView;

@property (weak) IBOutlet NSView *placeholderTabView;
@property (strong) IBOutlet NSView *notFoundTabView;

@property (strong) IBOutlet NSView *noAccessTabView;
@property (strong) IBOutlet NSView *normalDetailsTabView;
@property (strong) IBOutlet NSView *currentTabView;

@end



@implementation NewMainWindowController

@synthesize welcomePane = _welcomePane;
@synthesize welcomeMessageField = _welcomeMessageField;
@synthesize statusTextField = _statusTextField;
@synthesize terminalButton = _terminalButton;
@synthesize paneBorderBox = _paneBorderBox;
@synthesize panePlaceholder = _panePlaceholder;
@synthesize projectPane = _projectPane;
@synthesize titleBarSideView = _titleBarSideView;
@synthesize versionMenuItem = _versionMenuItem;
@synthesize openAtLoginMenuItem = _openAtLoginMenuItem;
@synthesize projectOutlineView = _projectOutlineView;
@synthesize addProjectButton = _addProjectButton;
@synthesize removeProjectButton = _removeProjectButton;
@synthesize gettingStartedView = _gettingStartedView;
@synthesize gettingStartedIconView = _gettingStartedIconView;
@synthesize gettingStartedLabelField = _gettingStartedLabelField;
@synthesize iconView = _iconView;
@synthesize nameTextField = _nameTextField;
@synthesize pathTextField = _pathTextField;
@synthesize snippetLabelField = _snippetLabelField;
@synthesize snippetBodyTextField = _snippetBodyTextField;
@synthesize monitoringSummaryLabelField = _monitoringSummaryLabelField;
@synthesize availableCompilersLabel = _availableCompilersLabel;

+ (NewMainWindowController *)sharedMainWindowController {
    LiveReloadAppDelegate *delegate = [NSApp delegate];
    return delegate.mainWindowController;
}

- (id)init {
    self = [super initWithWindowNibName:@"NewMainWindow"];
    if (self) {
        _projectsItem = [[NSObject alloc] init];

        _folderImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)];
        [_folderImage setSize:NSMakeSize(16,16)];
    }
    return self;
}

- (void)dealloc {
    [self removeAllObservationsOfObject:[AppState sharedAppState]];
}

- (NSShadow *)subtleWhiteShadow {
    static NSShadow *shadow = nil;
    if (shadow == nil) {
        shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.33]];
    }
    return shadow;
}

- (NSColor *)headerLabelColor {
    return [NSColor colorWithCalibratedRed:58.0/255 green:61.0/255 blue:64.0/255 alpha:1.0];
}

- (NSParagraphStyle *)paragraphStyleForLabel:(NSControl *)label {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setAlignment:label.alignment];
    return style;
}

- (void)styleLabel:(NSControl *)label color:(NSColor *)color shadow:(NSShadow *)shadow text:(NSString *)text {
    [label setAttributedStringValue:[[NSAttributedString alloc] initWithString:text attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]]];
}

- (void)styleLabel:(NSControl *)label color:(NSColor *)color shadow:(NSShadow *)shadow {
    [self styleLabel:label color:color shadow:shadow text:label.stringValue];
}

- (void)stylePartialHyperlink:(NSTextField *)label to:(NSURL *)url color:(NSColor *)color linkColor:(NSColor *)linkColor shadow:(NSShadow *)shadow {
    // both are needed, otherwise hyperlink won't accept mousedown
    [label setAllowsEditingTextAttributes:YES];
    [label setSelectable:YES];

    NSString *string = label.stringValue;
    NSRange range = [string rangeOfString:@"_["];
    NSAssert(range.length > 0, @"Partial hyperlink must contain _[ marker");
    NSString *prefix = [string substringToIndex:range.location];
    string = [string substringFromIndex:range.location + range.length];

    range = [string rangeOfString:@"]_"];
    NSAssert(range.length > 0, @"Partial hyperlink must contain ]_ marker");
    NSString *link = [string substringToIndex:range.location];
    NSString *suffix = [string substringFromIndex:range.location + range.length];

    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] init];

    if (shadow == nil) {
        shadow = [[NSShadow alloc] init];
    }

    [as appendAttributedString:[[NSAttributedString alloc] initWithString:prefix attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]]];

    [as appendAttributedString:[[NSAttributedString alloc] initWithString:link attributes:[NSDictionary dictionaryWithObjectsAndKeys:linkColor, NSForegroundColorAttributeName, [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, url, NSLinkAttributeName, label.font, NSFontAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, nil]]];

    [as appendAttributedString:[[NSAttributedString alloc] initWithString:suffix attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]]];

    label.attributedStringValue = as;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    _versionMenuItem.title = [NSString stringWithFormat:@"LiveReload %@", version];

    // add frame controls
    NSView *themeFrame = [self.window.contentView superview];
    CGFloat titleBarHeight = [self.window frame].size.height - [self.window contentRectForFrameRect:[self.window frame]].size.height - 2;
    _titleBarSideView.frame = NSMakeRect(themeFrame.frame.size.width - _titleBarSideView.frame.size.width - 16, themeFrame.frame.size.height - titleBarHeight + (titleBarHeight - _titleBarSideView.frame.size.height) / 2, _titleBarSideView.frame.size.width, _titleBarSideView.frame.size.height);
    _titleBarSideView.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
    [themeFrame addSubview:_titleBarSideView];

    [_projectOutlineView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [_projectOutlineView setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationLink forLocal:NO];

    [_nameTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_pathTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_statusTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_addProjectButton.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_removeProjectButton.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_gettingStartedIconView.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_gettingStartedLabelField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_terminalButton.cell setBackgroundStyle:NSBackgroundStyleRaised];

    [self stylePartialHyperlink:_snippetLabelField to:[NSURL URLWithString:@"http://help.livereload.com/kb/general-use/browser-extensions"] color:[NSColor blackColor] linkColor:[NSColor colorWithCalibratedRed:0 green:10/255.0 blue:137/255.0 alpha:1.0] shadow:nil];;

    NSTableColumn *tableColumn = [_projectOutlineView tableColumnWithIdentifier:@"Name"];
    ImageAndTextCell *imageAndTextCell = [[ImageAndTextCell alloc] init];
    [imageAndTextCell setEditable:YES];
    [tableColumn setDataCell:imageAndTextCell];

    [self updateProjectList];

    // scroll to the top in case the outline contents is very long
    [[[_projectOutlineView enclosingScrollView] verticalScroller] setFloatValue:0.0];
    [[[_projectOutlineView enclosingScrollView] contentView] scrollToPoint:NSMakePoint(0,0)];
    [_projectOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];

    _panes = [[NSArray alloc] initWithObjects:_welcomePane, _projectPane, nil];

    LiveReloadAppDelegate *delegate = [NSApp delegate];
    [_snippetBodyTextField setStringValue:[NSString stringWithFormat:@"<script>document.write('<script src=\"http://' + (location.host || 'localhost').split(':')[0] + ':%d/livereload.js?snipver=1\"></' + 'script>')</script>", delegate.port]];

    NSView *projectPaneContainer = [ATFlippedView new];
    NSView *projectOverview = _projectOverviewView;
    projectPaneContainer.translatesAutoresizingMaskIntoConstraints = NO;
    _projectOverviewView.translatesAutoresizingMaskIntoConstraints = NO;
    [projectPaneContainer addSubview:_projectOverviewView];
    _projectPaneScrollView.documentView = projectPaneContainer;

    NSDictionary *bindings = NSDictionaryOfVariableBindings(projectPaneContainer, projectOverview);
    [projectPaneContainer.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[projectPaneContainer]-0-|" options:0 metrics:nil views:bindings]];
    [projectPaneContainer.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[projectPaneContainer]" options:0 metrics:nil views:bindings]];
    [projectPaneContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-16-[projectOverview]-16-|" options:0 metrics:nil views:bindings]];
    [projectPaneContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-16-[projectOverview]-16-|" options:0 metrics:nil views:bindings]];

//    [_projectOverviewPlaceholderView replaceWithViewPreservingConstraints:_projectOverviewView];

    _actionsRowNib = [[NSNib alloc] initWithNibNamed:@"ActionRowView" bundle:nil];

    _currentPaneView = _panePlaceholder;
    _currentTabView = _placeholderTabView;

    // MUST be done after initializing _panes
    [_projectOutlineView expandItem:_projectsItem];
    [self restoreSelection];

    [self selectedProjectDidChange];
    [self updateItemStates];

    [self updateLicensingUI];

#ifdef APPSTORE
    checkForUpdatesMenuItem.hidden = YES;
    checkForUpdatesMenuItemSeparator.hidden = YES;
#endif

    [[Workspace sharedWorkspace] addObserver:self forKeyPath:@"projects" options:0 context:nil];

    [self observeObject:[AppState sharedAppState] properties:@[@"numberOfConnectedBrowsers", @"numberOfRefreshesProcessed"] withSelector:@selector(updateStatus)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLicensingUI) name:LicenseManagerStatusDidChangeNotification object:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
    if (_projectSettingsSheetController && [_projectSettingsSheetController isWindowLoaded]) {
        [NSApp endSheet:[_projectSettingsSheetController window]];
    }
}



#pragma mark - Panes

- (void)updateWelcomePane {
    if (_currentPane != PaneWelcome)
        return;
}

- (void)updateProjectPane {
    if (_currentPane != PaneProject)
        return;
//    [self styleLabel:_nameTextField color:[self headerLabelColor] shadow:[self subtleWhiteShadow] text:[_selectedProject.displayPath lastPathComponent]];
    _nameTextField.stringValue = [_selectedProject.displayPath lastPathComponent];
    _pathTextField.stringValue = [_selectedProject.displayPath stringByDeletingLastPathComponent];
//    [self styleLabel:_pathTextField color:[self headerLabelColor] shadow:[self subtleWhiteShadow] text:[_selectedProject.displayPath stringByDeletingLastPathComponent]];

    NSView *tabView = _normalDetailsTabView;
    if (!_selectedProject.exists)
        tabView = _notFoundTabView;
    else if (!_selectedProject.accessible)
        tabView = _noAccessTabView;

    if (_currentTabView != tabView) {
        [_currentTabView replaceWithViewPreservingConstraints:tabView];
        _currentTabView = tabView;
    }

    NSString *exclusionsString;
    int exclusionCount = _selectedProject.excludedPaths.count;
    switch (exclusionCount) {
        case 0:  exclusionsString = @"no exclusions"; break;
        case 1:  exclusionsString = @"1 exclusion"; break;
        default: exclusionsString = [NSString stringWithFormat:@"%d exclusions", exclusionCount]; break;
    }

    _monitoringSummaryLabelField.stringValue = [NSString stringWithFormat:@"Monitoring %d file extensions, %@ →", (int)[Preferences sharedPreferences].allExtensions.count, exclusionsString];

    _availableCompilersLabel.stringValue = [NSString stringWithFormat:@"%@", [[[PluginManager sharedPluginManager].compilers valueForKeyPath:@"name"] componentsJoinedByString:@", "]];

    [self updateURLs];
    [self renderActions];
}

- (Pane)choosePane {
    if (_selectedProject != nil)
        return PaneProject;
    else
        return PaneWelcome;
}

- (void)updatePanes {
    _currentPane = [self choosePane];
    NSView *paneView = [_panes objectAtIndex:_currentPane];

    if (_currentPaneView != paneView) {
        [_currentPaneView replaceWithViewPreservingConstraints:paneView];
        _currentPaneView = paneView;
    }

    [self updateWelcomePane];
    [self updateProjectPane];
}


#pragma mark - Project Pane

- (void)window:(NSWindow *)window didChangeFirstResponder:(NSResponder *)responder {
    if (responder == _snippetBodyTextField) {
        // doing this immediately does not work because NSTextField needs time to make its field editor the first responder
        // http://stackoverflow.com/questions/2195704/selecttext-of-nstextfield-on-focus
        [_snippetBodyTextField performSelector:@selector(selectText:) withObject:nil afterDelay:0.0];

        // not trying to copy automatically because this will require a stupid UI ("copied!" label),
        // and I physically miss pressing Command-C anyway
    }
}

- (IBAction)allowAccessToProject:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setPrompt:@"Allow Access"];
    [openPanel setCanChooseFiles:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    [openPanel setDirectoryURL:_selectedProject.rootURL];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [openPanel URL];
            [_selectedProject setRootURL:url];
            [_selectedProject updateAccessibility];
        }
    }];
}

- (IBAction)changeProjectPath:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setPrompt:@"Set Path"];
    [openPanel setCanChooseFiles:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    [openPanel setDirectoryURL:_selectedProject.rootURL];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [openPanel URL];
            [_selectedProject setRootURL:url];
            [_selectedProject updateAccessibility];
        }
    }];
}


#pragma mark - Terminal Mode

- (BOOL)isShowingTerminal {
    return _terminalViewController != nil;
}

- (void)showTerminal {
    if (![self isShowingTerminal]) {
        if (_terminalViewController == nil) {
            _terminalViewController = [[TerminalViewController alloc] init];
        }
        [self.window.contentView addSubview:_terminalViewController.view positioned:NSWindowBelow relativeTo:_terminalButton];

        [_terminalButton setImage:[NSImage imageNamed:@"LRTerminalButtonOn"]];
        [_terminalButton setAlternateImage:[NSImage imageNamed:@"LRTerminalButtonOnHighlight"]];

        CGRect bounds = [self.window.contentView bounds];
        CGRect startingBounds = bounds;
        startingBounds.origin.y -= startingBounds.size.height;
        _terminalViewController.view.frame = startingBounds;

        NSDictionary *effect = [NSDictionary dictionaryWithObjectsAndKeys:_terminalViewController.view, NSViewAnimationTargetKey, [NSValue valueWithRect:startingBounds], NSViewAnimationStartFrameKey, [NSValue valueWithRect:bounds], NSViewAnimationEndFrameKey, nil];
        NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:effect]];
        [animation setAnimationCurve:NSAnimationEaseIn];
        [animation setDuration:0.25];
        [animation startAnimation];
    }
}

- (void)hideTerminal {
    if ([self isShowingTerminal]) {
        [_terminalButton setImage:[NSImage imageNamed:@"LRTerminalButtonOff"]];
        [_terminalButton setAlternateImage:[NSImage imageNamed:@"LRTerminalButtonOffHighlight"]];

        CGRect bounds = [self.window.contentView bounds];
        CGRect finalBounds = bounds;
        finalBounds.origin.y -= finalBounds.size.height;

        NSDictionary *effect = [NSDictionary dictionaryWithObjectsAndKeys:_terminalViewController.view, NSViewAnimationTargetKey, [NSValue valueWithRect:bounds], NSViewAnimationStartFrameKey, [NSValue valueWithRect:finalBounds], NSViewAnimationEndFrameKey, nil];
        NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:effect]];
        [animation setDuration:0.25];
        [animation setDelegate:self];
        [animation startAnimation];
    }
}

- (void)animationDidEnd:(NSAnimation*)animation {
    [_terminalViewController.view removeFromSuperview];
    _terminalViewController = nil;
}

- (IBAction)toggleTerminal:(id)sender {
    if ([self isShowingTerminal]) {
        [self hideTerminal];
    } else {
        [self showTerminal];
    }
}



#pragma mark - NSOutlineView management

- (void)updateProjectList {
    _projects = [[Workspace sharedWorkspace].sortedProjects copy];
    [self updateStatus];
    [_projectOutlineView reloadData];
    [self restoreSelection];
}

- (void)restoreSelection {
    NSString *pathToSelect = [[NSUserDefaults standardUserDefaults] objectForKey:@"SelectedProjectPath"];

    Project *projectToSelect = nil;
    if (pathToSelect.length > 0) {
        for (Project *project in _projects) {
            if ([project.path isEqualToString:pathToSelect]) {
                projectToSelect = project;
                break;
            }
        }
    }

    NSInteger rowToSelect = -1;
    if (projectToSelect) {
        rowToSelect = [_projectOutlineView rowForItem:projectToSelect];
    }

    if (rowToSelect >= 0) {
        [_projectOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowToSelect] byExtendingSelection:NO];
    } else {
        [_projectOutlineView deselectAll:nil];
    }
}

- (void)selectedProjectDidChange {
    Project *newSelectedProject = nil;

    NSInteger row = _projectOutlineView.selectedRow;
    if (row >= 0) {
        id item = [_projectOutlineView itemAtRow:row];
        if ([item isKindOfClass:[Project class]]) {
            newSelectedProject = item;
        }
    }

    if (newSelectedProject != _selectedProject) {
        [self stopObservingSelectedProject];
        _selectedProject = newSelectedProject;
        [_selectedProject updateAccessibility];  // make sure the data is fresh
        [self startObservingSelectedProject];
    }

    if (_selectedProject)
        [[NSUserDefaults standardUserDefaults] setObject:_selectedProject.path forKey:@"SelectedProjectPath"];
    else
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SelectedProjectPath"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self updatePanes];
}

- (void)updateOutlineViewForProject:(Project *)project {
    [_projectOutlineView reloadItem:project];
}

- (void)startObservingSelectedProject {
    [_selectedProject addObserver:self forKeyPath:@"accessible" options:0 context:NULL];
    [_selectedProject addObserver:self forKeyPath:@"exists" options:0 context:NULL];
}

- (void)stopObservingSelectedProject {
    [_selectedProject removeObserver:self forKeyPath:@"accessible"];
    [_selectedProject removeObserver:self forKeyPath:@"exists"];
}


#pragma mark - NSOutlineView data source and delegate

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [self selectedProjectDidChange];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return (item != nil && item != _projectsItem);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return item == _projectsItem;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil)
        return _projectsItem;
    if (item == _projectsItem)
        return [_projects objectAtIndex:index];
    assert(0);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (item == nil)
        return YES;
    if (item == _projectsItem)
        return YES;
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return 1;
    if (item == _projectsItem)
        return [_projects count];
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSParameterAssert(item != nil);
    if (item == _projectsItem)
        return (_projects.count > 0 ? @"MONITORED FOLDERS" : @"");

    Project *project = (Project *)item;
    NSString *label = project.displayName;
    if (!project.exists)
        label = [NSString stringWithFormat:@"%@ (missing)", label];
    else if (!project.accessible)
        label = [NSString stringWithFormat:@"%@ (no access)", label];
//        return [NSAttributedString AT_attributedStringWithPrimaryString:label secondaryString:@" (no access)" primaryStyle:@{} secondaryStyle:@{NSForegroundColorAttributeName: [NSColor grayColor]}];
    return label;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([item isKindOfClass:[Project class]]) {
        NSString *name = object;
        Project *project = item;
        project.customName = name;
        project.numberOfPathComponentsToUseAsName = ProjectUseCustomName;
        [_projectOutlineView reloadData];
    }
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    ImageAndTextCell *theCell = cell;
    if (item == nil || item == _projectsItem) {
        theCell.image = nil;
    } else {
        theCell.image = _folderImage;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    return NO;
}

- (NSString *)outlineView:(NSOutlineView *)outlineView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    if (item == nil || item == _projectsItem) {
        return nil;
    } else {
        Project *project = item;
        return project.displayPath;
    }
}

//- (BOOL)selectionShouldChangeInOutlineView:(NSOutlineView *)outlineView;



#pragma mark - Actions

- (IBAction)addProjectClicked:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setPrompt:@"Choose folder"];
    [openPanel setCanChooseFiles:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [openPanel URL];
            NSString *path = [url path];
            [[NSApp delegate] addProjectAtPath:path];
        }
    }];
}

- (IBAction)removeProjectClicked:(id)sender {
    Project *project = _selectedProject;
    if (project) {
        [[Workspace sharedWorkspace] removeProjectsObject:project];
        [self updateProjectList];
        [_projectOutlineView deselectAll:nil];
    }
}


#pragma mark - Contextual menu

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.target == self) {
        if (menuItem.action == @selector(doNothingOnShowAs:)) {
            menuItem.enabled = NO;
            if (_selectedProject == nil) {
                menuItem.title = @"No project selected";
            } else {
                menuItem.title = @"Show As:";
            }
            return NO;
        } else if (menuItem.action == @selector(useProposedProjectName:)) {
            NSInteger numberOfPathComponentsToUseAsName = menuItem.tag - 1001 + 1;
            NSString *name = [_selectedProject proposedNameAtIndex:numberOfPathComponentsToUseAsName - 1];
            if (name) {
                menuItem.title = name;
                menuItem.hidden = NO;
            } else {
                menuItem.hidden = YES;
            }
            menuItem.state = (_selectedProject.numberOfPathComponentsToUseAsName == numberOfPathComponentsToUseAsName ? NSOnState : NSOffState);
        } else if (menuItem.action == @selector(usePreviouslySetCustomProjectName:)) {
            menuItem.title = _selectedProject.customName ?: @"";
            menuItem.hidden = (_selectedProject.customName.length == 0);
            menuItem.state = (_selectedProject.numberOfPathComponentsToUseAsName == ProjectUseCustomName ? NSOnState : NSOffState);
        } else if (menuItem.tag >= 500 && menuItem.tag <= 999) {
            menuItem.hidden = (_selectedProject == nil);
        }
        return YES;
    }
    return NO;
}

- (IBAction)useNewCustomProjectName:(NSMenuItem *)sender {
    NSInteger row = [_projectOutlineView rowForItem:_selectedProject];
    [_projectOutlineView editColumn:0 row:row withEvent:[NSApp currentEvent] select:YES];
}

- (IBAction)usePreviouslySetCustomProjectName:(NSMenuItem *)sender {
    if (_selectedProject.customName.length > 0) {
        _selectedProject.numberOfPathComponentsToUseAsName = ProjectUseCustomName;
        [_projectOutlineView reloadData];
    }
}

- (IBAction)useProposedProjectName:(NSMenuItem *)sender {
    _selectedProject.numberOfPathComponentsToUseAsName = sender.tag - 1000;
    [_projectOutlineView reloadData];
}

- (IBAction)doNothingOnShowAs:(id)sender {
}


#pragma mark - Settings menu

- (void)updateItemStates {
    _openAtLoginMenuItem.state = ([ATLoginItemController sharedController].loginItemEnabled ? NSOnState : NSOffState);

    AppVisibilityMode visibilityMode = [DockIcon currentDockIcon].visibilityMode;
    [_showInDockMenuItem setState:(visibilityMode == AppVisibilityModeDock ? NSOnState : NSOffState)];
    [_showInMenuBarMenuItem setState:(visibilityMode == AppVisibilityModeMenuBar ? NSOnState : NSOffState)];
    [_showNowhereMenuItem setState:(visibilityMode == AppVisibilityModeNone ? NSOnState : NSOffState)];
}

- (IBAction)toggleOpenAtLogin:(id)sender {
    [ATLoginItemController sharedController].loginItemEnabled = ![ATLoginItemController sharedController].loginItemEnabled;
    [self updateItemStates];
}

- (IBAction)toggleVisibilityMode:(NSMenuItem *)sender {
    [DockIcon currentDockIcon].visibilityMode = (AppVisibilityMode)sender.tag;
    [self updateItemStates];
}

- (IBAction)performQuit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)showPreferences:(id)sender {
    [[PreferencesController sharedPreferencesController] show];
}


#pragma mark - Help menu

- (IBAction)performHelp:(id)sender {
    TenderDisplayHelp();
}

- (IBAction)performKeyboardHelp:(id)sender {
    TenderShowArticle(@"general-use/keyboard-shortcuts");
}

- (IBAction)performWebSite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://livereload.com/"]];
}

- (IBAction)performReportProblem:(id)sender {
    TenderStartDiscussionIn(@"problems");
}

- (IBAction)performAskQuestion:(id)sender {
    TenderStartDiscussionIn(@"questions");
}

- (IBAction)performSuggest:(id)sender {
    TenderStartDiscussionIn(@"suggestions");
}

- (IBAction)helpSupportClicked:(NSSegmentedControl *)sender {
    if (sender.selectedSegment == 0) {
        [[NSApp delegate] openHelp:self];
    } else {
        [[NSApp delegate] openSupport:self];
    }
}


#pragma mark - Model change handling

- (void)projectAdded:(Project *)project {
    if ([self isWindowLoaded]) {
        [self updateProjectList];
        NSInteger row = [_projectOutlineView rowForItem:project];
        [_projectOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
}

- (void)projectListDidChange {
    if ([self isWindowLoaded]) {
        [self updateProjectList];
        [self restoreSelection];
    }
}


#pragma mark - Drag'n'drop

- (NSArray *)sanitizedPathsFrom:(NSPasteboard *)pboard {
    NSLog(@"Got types: %@", [pboard types]);
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

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    NSMutableArray *files = [NSMutableArray arrayWithCapacity:items.count];
    for (id item in items) {
        if ([item isKindOfClass:[Project class]]) {
            Project *project = item;
            [files addObject:project.path];
        }
    }
    if (files.count > 0) {
        [pasteboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:self];
        [pasteboard setPropertyList:[NSArray arrayWithArray:files] forType:NSFilenamesPboardType];
        return YES;
    } else {
        return NO;
    }
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    BOOL genericSupported = (NSDragOperationGeneric & [info draggingSourceOperationMask]) == NSDragOperationGeneric;
    NSArray *files = [self sanitizedPathsFrom:[info draggingPasteboard]];
    if (genericSupported && [files count] > 0) {
        [outlineView setDropItem:nil dropChildIndex:-1];
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    BOOL genericSupported = (NSDragOperationGeneric & [info draggingSourceOperationMask]) == NSDragOperationGeneric;
    NSArray *paths = [self sanitizedPathsFrom:[info draggingPasteboard]];
    if (genericSupported && [paths count] > 0) {
        [[NSApp delegate] addProjectsAtPaths:paths];
        return YES;
    } else {
        return NO;
    }
}


#pragma mark - Project settings (general)

- (void)showProjectSettingsSheet:(Class)klass {
    NSWindowController *controller = [[klass alloc] initWithProject:_selectedProject];
    _projectSettingsSheetController = controller;
    [NSApp beginSheet:_projectSettingsSheetController.window
       modalForWindow:self.window
        modalDelegate:self
       didEndSelector:@selector(didEndProjectSettingsSheet:returnCode:contextInfo:)
          contextInfo:nil];
}

- (void)didEndProjectSettingsSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];

    // at least on OS X 10.6, the window position is only persisted on quit
    [[NSUserDefaults standardUserDefaults] performSelector:@selector(synchronize) withObject:nil afterDelay:2.0];

    _projectSettingsSheetController = nil;

    [self updateProjectPane];
}


#pragma mark - Project settings (monitoring)

- (IBAction)showMonitoringOptions:(id)sender {
    [self showProjectSettingsSheet:[MonitoringSettingsWindowController class]];
}


#pragma mark - Actions Table

- (void)renderActions {
    self.actionsStackView.project = _selectedProject;
}


#pragma mark - Status

- (void)updateStatus {
    AppState *appState = [AppState sharedAppState];
    NSString *text;
    if (_projects.count == 0) {
        text = @"";
        [_gettingStartedView setHidden:NO];
    } else {
        [_gettingStartedView setHidden:YES];
        NSInteger n = appState.numberOfConnectedBrowsers;
        if (n == 0) {
            text = @"Waiting for a browser to connect.";
        } else if (n == 1) {
            text = [NSString stringWithFormat:@"1 browser connected, %d changes detected so far.", (int)appState.numberOfRefreshesProcessed];
        } else {
            text = [NSString stringWithFormat:@"%d browsers connected, %d changes detected so far.", (int)n, (int)appState.numberOfRefreshesProcessed];
        }
    }
    _statusTextField.stringValue = text;
}

- (void)communicationStateChanged:(NSNotification *)notification {
    [self updateStatus];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"projects"]) {
        [self projectListDidChange];
    } else if ([keyPath isEqualToString:@"numberOfProcessedChanges"]) {
        [self updateStatus];
    } else if ([keyPath isEqualToString:@"accessible"] || [keyPath isEqualToString:@"exists"]) {
        [self updatePanes];
        [self updateOutlineViewForProject:object];
    }
}


#pragma mark - Licensing

- (void)updateLicensingUI {
    BOOL all = LicenseManagerShouldDisplayLicensingUI();
    BOOL code = LicenseManagerShouldDisplayLicenseCodeUI();
    BOOL purchasing = LicenseManagerShouldDisplayPurchasingUI();

    purchasePopUpButton.hidden = !purchasing;
    displayLicenseManagerMenuItem.hidden = !code;
    displayLicenseManagerMenuItemSeparator.hidden = !code;

    NSString *licenseStatus;
    if (LicenseManagerIsTrialMode()) {
        licenseStatus = @"Trial mode";
    } else {
        switch (LicenseManagerGetCodeStatus()) {
            case LicenseManagerCodeStatusNotRequired:
                licenseStatus = @"Licensed via the Mac App Store";
                break;
            case LicenseManagerCodeStatusNotEntered:
                break;
            case LicenseManagerCodeStatusAcceptedIndividual:
                licenseStatus = @"Individual license";
                break;
            case LicenseManagerCodeStatusAcceptedBusiness:
                licenseStatus = @"Per-seat business license";
                break;
            case LicenseManagerCodeStatusAcceptedBusinessUnlimited:
                licenseStatus = @"Unlimited business license";
                break;
            case LicenseManagerCodeStatusAcceptedUnknown:
                licenseStatus = @"Unknown valid license";
                break;
            default:
                licenseStatus = @"";
        }
    }
    licenseStatusMenuItem.hidden = !all;
    licenseStatusMenuItem.title = licenseStatus;

    // TODO: re-enable when out of beta
#if 1
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.window.title = [NSString stringWithFormat:@"LiveReload Pro (early preview %@)", version];
#else
    if (LicenseManagerIsTrialMode())
        self.window.title = @"LiveReload Pro — unlimited trial, please purchase when ready";
    else
        self.window.title = @"LiveReload Pro";
#endif
}

- (IBAction)purchaseViaMAS:(id)sender {
    if (![[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"macappstore://itunes.apple.com/app/id482898991?mt=12"]]) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/livereload/id482898991?mt=12"]];
    }
}

- (IBAction)purchaseOutsideMAS:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://go.livereload.com/purchase"]];
}

- (IBAction)displayLicenseManager:(id)sender {
    [[LicenseCodeWindowController sharedLicenseCodeWindowController] showWindow:nil];
}

- (IBAction)enterLicenseCode:(id)sender {
    [self displayLicenseManager:sender];
}


#pragma mark - URLs

- (void)updateURLs {
    urlsTextField.stringValue = _selectedProject.formattedUrlMaskList;
}

- (void)controlTextDidBeginEditing:(NSNotification *)obj {

}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    _selectedProject.formattedUrlMaskList = urlsTextField.stringValue;
    [self updateURLs];
}

- (void)controlTextDidChange:(NSNotification *)obj {

}

@end
