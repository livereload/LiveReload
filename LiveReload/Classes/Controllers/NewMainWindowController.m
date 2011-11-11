
#import "NewMainWindowController.h"

#import "MonitoringSettingsWindowController.h"
#import "CompilationSettingsWindowController.h"
#import "PostProcessingSettingsWindowController.h"
#import "CommunicationController.h"

#import "LiveReloadAppDelegate.h"
#import "PluginManager.h"
#import "Compiler.h"

#import "ImageAndTextCell.h"

#import "Workspace.h"
#import "Project.h"
#import "Preferences.h"


typedef enum {
    PaneWelcome,
    PaneProject,
} Pane;
enum { PANE_COUNT = PaneProject+1 };


@interface NewMainWindowController ()

- (void)updatePanes;
- (void)updateProjectList;
- (void)restoreSelection;
- (void)selectedProjectDidChange;

- (void)showProjectSettingsSheet:(Class)klass;

- (void)updateStatus;

@end


@implementation NewMainWindowController

@synthesize welcomePane = _welcomePane;
@synthesize welcomeMessageField = _welcomeMessageField;
@synthesize statusTextField = _statusTextField;
@synthesize paneBorderBox = _paneBorderBox;
@synthesize panePlaceholder = _panePlaceholder;
@synthesize projectPane = _projectPane;
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
@synthesize monitoringSummaryLabelField = _monitoringSummaryLabelField;
@synthesize compilerEnabledCheckBox = _compilerEnabledCheckBox;
@synthesize postProcessingEnabledCheckBox = _postProcessingEnabledCheckBox;
@synthesize availableCompilersLabel = _availableCompilersLabel;

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
    self.window.title = [NSString stringWithFormat:@"LiveReload %@", version];

    [_projectOutlineView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [_projectOutlineView setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationLink forLocal:NO];

    [_nameTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_pathTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_statusTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_addProjectButton.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_removeProjectButton.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_gettingStartedIconView.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_gettingStartedLabelField.cell setBackgroundStyle:NSBackgroundStyleRaised];

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

    [_projectOutlineView expandItem:_projectsItem];
    [self restoreSelection];

    _panes = [[NSArray alloc] initWithObjects:_welcomePane, _projectPane, nil];

    [self selectedProjectDidChange];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(communicationStateChanged:) name:CommunicationStateChangedNotification object:nil];
    [[CommunicationController sharedCommunicationController] addObserver:self forKeyPath:@"numberOfProcessedChanges" options:0 context:nil];
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
            [self.window.contentView addSubview:paneView];
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
    return [((Project *)item).path lastPathComponent];
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

- (IBAction)helpSupportClicked:(NSSegmentedControl *)sender {
    if (sender.selectedSegment == 0) {
        [[NSApp delegate] openHelp:self];
    } else {
        [[NSApp delegate] openSupport:self];
    }
}


#pragma mark - Model change handling

- (void)projectAdded:(Project *)project {
    [self updateProjectList];
    NSInteger row = [_projectOutlineView rowForItem:project];
    [_projectOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
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
        NSInteger n = [CommunicationController sharedCommunicationController].numberOfSessions;
        if (n == 0) {
            text = @"Waiting for a browser to connect.";
        } else if (n == 1) {
            text = [NSString stringWithFormat:@"1 browser connected, %d changes detected so far.", [CommunicationController sharedCommunicationController].numberOfProcessedChanges];
        } else {
            text = [NSString stringWithFormat:@"%d browsers connected, %d changes detected so far.", n, [CommunicationController sharedCommunicationController].numberOfProcessedChanges];
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
        [self updateProjectList];
    } else if ([keyPath isEqualToString:@"numberOfProcessedChanges"]) {
        [self updateStatus];
    }
}


@end
