
#import "NewMainWindowController.h"

#import "MonitoringSettingsWindowController.h"
#import "CompilationSettingsWindowController.h"
#import "PostProcessingSettingsWindowController.h"
#import "TerminalViewController.h"
#import "LicenseCodeWindowController.h"

#import "LiveReloadAppDelegate.h"
#import "PluginManager.h"
#import "Compiler.h"

#import "ImageAndTextCell.h"

#import "Workspace.h"
#import "Project.h"
#import "Preferences.h"

#import "Stats.h"
#import "ShitHappens.h"
#import "VersionChecks.h"
#import "LoginItemController.h"
#import "DockIcon.h"
#import "LicenseManager.h"

#import "jansson.h"


typedef enum {
    PaneWelcome,
    PaneProject,
} Pane;
enum { PANE_COUNT = PaneProject+1 };


@interface NewMainWindowController () <NSAnimationDelegate>

+ (NewMainWindowController *)sharedMainWindowController;

- (void)updatePanes;
- (void)updateProjectList;
- (void)restoreSelection;
- (void)selectedProjectDidChange;

- (void)showProjectSettingsSheet:(Class)klass;

- (void)updateStatus;

- (void)updateItemStates;

- (void)updateLicensingUI;

@end


int browsers_connected = 0;
int changes_processed = 0;

void C_mainwnd__set_connection_status(json_t *arg) {
    browsers_connected = json_integer_value(json_object_get(arg, "connectionCount"));
    [[NewMainWindowController sharedMainWindowController] updateStatus];
}

void C_mainwnd__set_change_count(json_t *arg) {
    changes_processed = json_integer_value(json_object_get(arg, "changeCount"));
    [[NewMainWindowController sharedMainWindowController] updateStatus];
}


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
@synthesize compilerEnabledCheckBox = _compilerEnabledCheckBox;
@synthesize postProcessingEnabledCheckBox = _postProcessingEnabledCheckBox;
@synthesize availableCompilersLabel = _availableCompilersLabel;

+ (NewMainWindowController *)sharedMainWindowController {
    LiveReloadAppDelegate *delegate = [NSApp delegate];
    return delegate.mainWindowController;
}

- (id)init {
    self = [super initWithWindowNibName:@"NewMainWindow"];
    if (self) {
        _projectsItem = [[NSObject alloc] init];

        _folderImage = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)] retain];
        [_folderImage setSize:NSMakeSize(16,16)];
    }
    return self;
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
    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [style setAlignment:label.alignment];
    return style;
}

- (void)styleLabel:(NSControl *)label color:(NSColor *)color shadow:(NSShadow *)shadow text:(NSString *)text {
    [label setAttributedStringValue:[[[NSAttributedString alloc] initWithString:text attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]] autorelease]];
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

    NSMutableAttributedString *as = [[[NSMutableAttributedString alloc] init] autorelease];

    if (shadow == nil) {
        shadow = [[[NSShadow alloc] init] autorelease];
    }

    [as appendAttributedString:[[[NSAttributedString alloc] initWithString:prefix attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]] autorelease]];

    [as appendAttributedString:[[[NSAttributedString alloc] initWithString:link attributes:[NSDictionary dictionaryWithObjectsAndKeys:linkColor, NSForegroundColorAttributeName, [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, url, NSLinkAttributeName, label.font, NSFontAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, nil]] autorelease]];

    [as appendAttributedString:[[[NSAttributedString alloc] initWithString:suffix attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]] autorelease]];

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
    ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
    [imageAndTextCell setEditable:YES];
    [tableColumn setDataCell:imageAndTextCell];

    [self updateProjectList];

    // scroll to the top in case the outline contents is very long
    [[[_projectOutlineView enclosingScrollView] verticalScroller] setFloatValue:0.0];
    [[[_projectOutlineView enclosingScrollView] contentView] scrollToPoint:NSMakePoint(0,0)];
    [_projectOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];

    _panes = [[NSArray alloc] initWithObjects:_welcomePane, _projectPane, nil];

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLicensingUI) name:LicenseManagerStatusDidChangeNotification object:nil];
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];
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
    _monitoringSummaryLabelField.stringValue = [NSString stringWithFormat:@"Monitoring %d file extensions.", [Preferences sharedPreferences].allExtensions.count];
    [_compilerEnabledCheckBox setState:_selectedProject.compilationEnabled ? NSOnState : NSOffState];
    [_postProcessingEnabledCheckBox setState:_selectedProject.postProcessingEnabled ? NSOnState : NSOffState];

    _availableCompilersLabel.stringValue = [NSString stringWithFormat:@"Available compilers: %@.", [[[PluginManager sharedPluginManager].compilers valueForKeyPath:@"name"] componentsJoinedByString:@", "]];
}

- (void)setVisibility:(BOOL)visible forPaneView:(NSView *)paneView {
    if (paneView.superview) {
        if (!visible)
            [paneView removeFromSuperview];
    } else {
        if (visible) {
            [self.window.contentView addSubview:paneView positioned:NSWindowBelow relativeTo:_panePlaceholder];
            paneView.frame = _panePlaceholder.frame;
        }
    }
}

- (Pane)choosePane {
    if (_selectedProject != nil)
        return PaneProject;
    else
        return PaneWelcome;
}

- (void)updatePanes {
    _currentPane = [self choosePane];

    for (Pane pane = 0; pane < PANE_COUNT; ++pane) {
        [self setVisibility:(pane == _currentPane) forPaneView:[_panes objectAtIndex:pane]];
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
        NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:effect]] autorelease];
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
        NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:effect]] autorelease];
        [animation setDuration:0.25];
        [animation setDelegate:self];
        [animation startAnimation];
    }
}

- (void)animationDidEnd:(NSAnimation*)animation {
    [_terminalViewController.view removeFromSuperview];
    [_terminalViewController release], _terminalViewController = nil;
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
    [_selectedProject release], _selectedProject = nil;

    NSInteger row = _projectOutlineView.selectedRow;
    if (row >= 0) {
        id item = [_projectOutlineView itemAtRow:row];
        if ([item isKindOfClass:[Project class]]) {
            _selectedProject = [item retain];
        }
    }

    if (_selectedProject)
        [[NSUserDefaults standardUserDefaults] setObject:_selectedProject.path forKey:@"SelectedProjectPath"];
    else
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SelectedProjectPath"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self updatePanes];
}


#pragma mark - NSOutlineView data source and delegate

- (NSArray *)saveActions {
    static NSArray *actions = nil;
    if (!actions) {
        actions = [[NSArray arrayWithObjects:
                   [NSDictionary dictionaryWithObjectsAndKeys:@"Watch Local Folder", @"label", @"ActionGeneric", @"icon", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:@"Compile SASS", @"label", @"ActionCompile", @"icon", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:@"Compile CoffeeScript", @"label", @"ActionCompile", @"icon", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:@"Minify & Concatenate", @"label", @"ActionMinify", @"icon", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:@"Run Script", @"label", @"ActionRunScript", @"icon", nil],
                   [NSDictionary dictionaryWithObjectsAndKeys:@"Refresh Browsers", @"label", @"ActionRefresh", @"icon", nil],
                    [NSDictionary dictionaryWithObjectsAndKeys:@"Add More", @"label", @"ActionAll", @"icon", nil],
                   nil] retain];
    }
    return actions;
}

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
    if (TryActionsInSourceList && [item isKindOfClass:[Project class]])
        return [[self saveActions] objectAtIndex:index];
    assert(0);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (item == nil)
        return YES;
    if (item == _projectsItem)
        return YES;
    if (TryActionsInSourceList && [item isKindOfClass:[Project class]])
        return YES;
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return 1;
    if (item == _projectsItem)
        return [_projects count];
    if (TryActionsInSourceList && [item isKindOfClass:[Project class]])
        return [[self saveActions] count];
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    NSParameterAssert(item != nil);
    if (item == _projectsItem)
        return (_projects.count > 0 ? @"MONITORED FOLDERS" : @"");
    if ([item isKindOfClass:[Project class]])
        return [(Project *)item displayName];
    if (TryActionsInSourceList && [item isKindOfClass:[NSDictionary class]])
        return [item objectForKey:@"label"];
    assert(0);
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
    } else if ([item isKindOfClass:[Project class]]) {
        theCell.image = _folderImage;
    } else if ([item isKindOfClass:[NSDictionary class]]) {
        theCell.image = [NSImage imageNamed:[item objectForKey:@"icon"]];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    if (TryActionsInSourceList && [item isKindOfClass:[Project class]])
        return YES;
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
    if (TryActionsInSourceList && [item isKindOfClass:[Project class]])
        return YES;
    return NO;
}

- (NSString *)outlineView:(NSOutlineView *)outlineView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn item:(id)item mouseLocation:(NSPoint)mouseLocation {
    if (item == nil || item == _projectsItem) {
        return nil;
    } else if ([item isKindOfClass:[Project class]]) {
        Project *project = item;
        return project.displayPath;
    } else {
        return nil;
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
    _openAtLoginMenuItem.state = ([LoginItemController sharedController].loginItemEnabled ? NSOnState : NSOffState);
    
    AppVisibilityMode visibilityMode = [DockIcon currentDockIcon].visibilityMode;
    [_showInDockMenuItem setState:(visibilityMode == AppVisibilityModeDock ? NSOnState : NSOffState)];
    [_showInMenuBarMenuItem setState:(visibilityMode == AppVisibilityModeMenuBar ? NSOnState : NSOffState)];
    [_showNowhereMenuItem setState:(visibilityMode == AppVisibilityModeNone ? NSOnState : NSOffState)];
}

- (IBAction)toggleOpenAtLogin:(id)sender {
    [LoginItemController sharedController].loginItemEnabled = ![LoginItemController sharedController].loginItemEnabled;
    [self updateItemStates];
}

- (IBAction)toggleVisibilityMode:(NSMenuItem *)sender {
    [DockIcon currentDockIcon].visibilityMode = (AppVisibilityMode)sender.tag;
    [self updateItemStates];
}

- (IBAction)performQuit:(id)sender {
    [NSApp terminate:self];
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
    NSWindowController *controller = [[[klass alloc] initWithProject:_selectedProject] autorelease];
    _projectSettingsSheetController = [controller retain];
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

    [_projectSettingsSheetController release], _projectSettingsSheetController = nil;

    [self updateProjectPane];
}


#pragma mark - Project settings (monitoring)

- (IBAction)showMonitoringOptions:(id)sender {
    [self showProjectSettingsSheet:[MonitoringSettingsWindowController class]];
}


#pragma mark - Project settings (compilation)

- (IBAction)showCompilationOptions:(id)sender {
    [self showProjectSettingsSheet:[CompilationSettingsWindowController class]];
}

- (IBAction)toggleCompilationEnabledCheckboxClicked:(NSButton *)sender {
    _selectedProject.compilationEnabled = !_selectedProject.compilationEnabled;
}


#pragma mark - Project settings (post-processing)

- (IBAction)togglePostProcessingCheckboxClicked:(NSButton *)sender {
    if (sender.state == NSOnState && _selectedProject.postProcessingCommand.length == 0) {
        [self showPostProcessingOptions:nil];
    } else {
        _selectedProject.postProcessingEnabled = (sender.state == NSOnState);
    }
}

- (IBAction)showPostProcessingOptions:(id)sender {
    [self showProjectSettingsSheet:[PostProcessingSettingsWindowController class]];
}


#pragma mark - Status

- (void)updateStatus {
    NSString *text;
    if (_projects.count == 0) {
        text = @"";
        [_gettingStartedView setHidden:NO];
    } else {
        [_gettingStartedView setHidden:YES];
        NSInteger n = browsers_connected;
        if (n == 0) {
            text = @"Waiting for a browser to connect.";
        } else if (n == 1) {
            text = [NSString stringWithFormat:@"1 browser connected, %d changes detected so far.", changes_processed];
        } else {
            text = [NSString stringWithFormat:@"%d browsers connected, %d changes detected so far.", n, changes_processed];
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
    
    if (LicenseManagerIsTrialMode())
        self.window.title = @"LiveReload — unlimited trial, please purchase when ready";
    else
        self.window.title = @"LiveReload";
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

@end
