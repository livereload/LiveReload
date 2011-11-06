
#import "NewMainWindowController.h"
#import "LiveReloadAppDelegate.h"

#import "ImageAndTextCell.h"

#import "Workspace.h"
#import "Project.h"


@interface NewMainWindowController ()

@property(nonatomic, readonly) Project *selectedProject;

- (void)updateProjectList;

@end


@implementation NewMainWindowController

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
}


#pragma mark - NSOutlineView management

- (void)updateProjectList {
    _projects = [[Workspace sharedWorkspace].sortedProjects copy];
    [_projectOutlineView reloadData];
}

- (Project *)selectedProject {
    NSInteger row = _projectOutlineView.selectedRow;
    if (row >= 0) {
        id item = [_projectOutlineView itemAtRow:row];
        if ([item isKindOfClass:[Project class]]) {
            return item;
        }
    }
    return nil;
}


#pragma mark - NSOutlineView data source and delegate

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

- (IBAction)showMonitoringOptions:(id)sender {
}

- (IBAction)showCompilationOptions:(id)sender {
}

- (IBAction)showPostProcessingOptions:(id)sender {
}

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
    Project *project = self.selectedProject;
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


@end
