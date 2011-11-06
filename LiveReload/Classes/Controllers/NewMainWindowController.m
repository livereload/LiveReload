
#import "NewMainWindowController.h"
#import "PostProcessingSettingsWindowController.h"

#import "LiveReloadAppDelegate.h"

#import "ImageAndTextCell.h"

#import "Workspace.h"
#import "Project.h"


typedef enum {
    PaneWelcome,
    PaneProject,
} Pane;
enum { PANE_COUNT = PaneProject+1 };


@interface NewMainWindowController ()

- (void)updatePanes;
- (void)updateProjectList;
- (void)selectedProjectDidChange;

@end


@implementation NewMainWindowController

@synthesize welcomePane = _welcomePane;
@synthesize welcomeMessageField = _welcomeMessageField;
@synthesize paneBorderBox = _paneBorderBox;
@synthesize panePlaceholder = _panePlaceholder;
@synthesize projectPane = _projectPane;
@synthesize projectOutlineView = _projectOutlineView;
@synthesize pathTextField = _pathTextField;
@synthesize compilerEnabledCheckBox = _compilerEnabledCheckBox;
@synthesize postProcessingEnabledCheckBox = _postProcessingEnabledCheckBox;

- (id)init {
    self = [super initWithWindowNibName:@"NewMainWindow"];
    if (self) {
        _projectsItem = [[NSObject alloc] init];

        _folderImage = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)] retain];
        [_folderImage setSize:NSMakeSize(16,16)];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    self.window.title = [NSString stringWithFormat:@"LiveReload %@", version];

    [_projectOutlineView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [_projectOutlineView setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationLink forLocal:NO];

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

    _panes = [[NSArray alloc] initWithObjects:_welcomePane, _projectPane, nil];

    [self selectedProjectDidChange];
}


#pragma mark - Panes

- (void)updateWelcomePane {
    if (_currentPane != PaneWelcome)
        return;
}

- (void)updateProjectPane {
    if (_currentPane != PaneProject)
        return;
    _pathTextField.stringValue = _selectedProject.displayPath;
    [_postProcessingEnabledCheckBox setState:_selectedProject.postProcessingEnabled ? NSOnState : NSOffState];
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
    [_projectOutlineView reloadData];
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
        return @"MONITORED FOLDERS";
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

- (void)addProjectClicked {
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

- (void)removeProjectClicked {
    Project *project = _selectedProject;
    if (project) {
        [[Workspace sharedWorkspace] removeProjectsObject:project];
        [self updateProjectList];
        [_projectOutlineView deselectAll:nil];
    }
}

- (IBAction)addRemoveClicked:(NSSegmentedControl *)sender {
    if (sender.selectedSegment == 0)
        [self addProjectClicked];
    else
        [self removeProjectClicked];
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


#pragma mark - Project settings

- (IBAction)showMonitoringOptions:(id)sender {
}

- (IBAction)showCompilationOptions:(id)sender {
}

- (IBAction)togglePostProcessingCheckboxClicked:(NSButton *)sender {
    if (sender.state == NSOnState && _selectedProject.postProcessingCommand.length == 0) {
        [self showPostProcessingOptions:nil];
    } else {
        _selectedProject.postProcessingEnabled = (sender.state == NSOnState);
    }
}

- (IBAction)showPostProcessingOptions:(id)sender {
    PostProcessingSettingsWindowController *controller = [[PostProcessingSettingsWindowController alloc] initWithProject:_selectedProject];
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

    [_projectSettingsSheetController release], _projectSettingsSheetController = nil;

    [self updateProjectPane];
}



@end
