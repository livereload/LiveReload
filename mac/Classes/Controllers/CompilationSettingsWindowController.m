
#import "CompilationSettingsWindowController.h"

#import "PluginManager.h"
#import "Compiler.h"
#import "ToolOptions.h"
#import "CompilationOptions.h"
#import "FileCompilationOptions.h"
#import "Project.h"
#import "Runtimes.h"
#import "PreferencesController.h"

#import "UIBuilder.h"
#import "sglib.h"
#include "kvec.h"
#include "stringutil.h"
#include "jansson.h"



typedef enum {
    compilation_settings_tab_options,
    compilation_settings_tab_paths,
} compilation_settings_tab_t;

typedef enum {
    output_paths_table_column_enable,
    output_paths_table_column_source,
    output_paths_table_column_output,
} output_paths_table_column_t;

const char *output_paths_table_column_ids[] = { "on", "source", "output" };



@interface CompilationSettingsWindowController () <NSTabViewDelegate, NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate, NSTextFieldDelegate> {
    NSArray               *_compilerOptions;

    NSArray               *_rubyInstances;

    CGFloat                _compilerSettingsWindowHeight;
    CGFloat                _outputPathsWindowHeight;

    NSMutableArray        *_fileList;  // of FileCompilationOptions

    IBOutlet NSButton     *_changeOutputFileButton;
    IBOutlet NSTextField  *_outputFileNameMask;
    IBOutlet NSButton     *_applyOutputFileNameMaskButton;
    IBOutlet NSButton     *_applyButton;
    
    NSSet                 *_bulkMaskEditingFiles;
    BOOL                   _bulkMaskEditingInProgress;
}

- (void)populateToolVersions;
- (void)updateOutputPathsTabData;
- (void)resizeWindowForTab:(NSTabViewItem *)item animated:(BOOL)animated;
- (void)didDetectChange;

- (void)updateOutputPathsButtonStates;
- (void)updateApplyMaskButton;
- (NSString *)draftFileNameMask;
- (void)endBulkMaskEditing;

@end


@implementation CompilationSettingsWindowController

@synthesize rubyVersionsPopUpButton = _rubyVersionsPopUpButton;
@synthesize tabView = _tabView;
@synthesize compilerSettingsTabView = _compilerSettingsTabView;
@synthesize pathTableView = _pathTableView;
@synthesize chooseFolderButton = _chooseFolderButton;

- (void)dealloc {
    [_compilerOptions release], _compilerOptions = nil;
    [_fileList release];
    [super dealloc];
}

- (void)windowDidLoad {
    _outputPathsWindowHeight = _tabView.frame.size.height;
    [_project requestMonitoring:YES forKey:@"compilationSettings"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDetectChange) name:ProjectDidDetectChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rubiesDidChange:) name:LRRuntimesDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rubiesDidChange:) name:LRRuntimeInstanceDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rubiesDidChange:) name:LRRuntimeContainerDidChangeNotification object:nil];
    [super windowDidLoad];
}

- (IBAction)dismiss:(id)sender {
    [_project requestMonitoring:NO forKey:@"compilationSettings"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ProjectDidDetectChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LRRuntimesDidChangeNotification object:nil];
    [super dismiss:sender];
}



#pragma mark - Actions

- (IBAction)showHelp:(id)sender {
    TenderShowArticle(@"features/compilation");
}


#pragma mark - Compiler settings

- (void)renderOptions:(NSArray *)options forCompiler:(Compiler *)compiler withBuilder:(UIBuilder *)builder isFirst:(BOOL *)isFirstCompiler {
    if (!*isFirstCompiler)
        [builder addVisualBreak];
    *isFirstCompiler = NO;

    BOOL isFirst = YES;
    for (ToolOption *option in options) {
        [option renderWithBuilder:builder];

        if (isFirst && !builder.labelAdded) {
            [builder addLabel:[NSString stringWithFormat:@"%@:", compiler.name]];
        }
        isFirst = NO;
    }

    if (isFirst) {
        [builder addRightLabel:@"No options for this compiler"];
        [builder addLabel:[NSString stringWithFormat:@"%@:", compiler.name]];
    }
}


#pragma mark - Model sync

- (void)renderCompilerOptions {
    NSArray *compilers = _project.compilersInUse;
    NSMutableArray *allOptions = [[NSMutableArray alloc] init];

    UIBuilder *builder = [[UIBuilder alloc] initWithView:_compilerSettingsTabView];
    CGFloat heightDelta = [builder buildUIWithTopInset:8 bottomInset:12 block:^{
        if (compilers.count > 0) {
            BOOL isFirst = YES;
            for (Compiler *compiler in compilers) {
                NSArray *options = [compiler optionsForProject:_project];

                EnabledToolOption *enabledOption = [[[EnabledToolOption alloc] initWithCompiler:compiler project:_project optionInfo:nil] autorelease];
                options = [[NSArray arrayWithObject:enabledOption] arrayByAddingObjectsFromArray:options];

                [self renderOptions:options forCompiler:compiler withBuilder:builder isFirst:&isFirst];
                [allOptions addObjectsFromArray:options];
            }
        } else {
            [builder addFullWidthLabel:@"No compilable files found in this folder."];
        }
    }];
    [builder release];

    _compilerSettingsWindowHeight = _outputPathsWindowHeight + heightDelta;

    _compilerOptions = [[NSArray alloc] initWithArray:allOptions];
    [allOptions release];
}

- (void)render {
    [self renderCompilerOptions];
    [self populateToolVersions];
    [self updateOutputPathsTabData];
    NSString *tabIdentifier = [[NSUserDefaults standardUserDefaults] objectForKey:@"compilationOptionsTab"];
    if (tabIdentifier) {
        [_tabView selectTabViewItemWithIdentifier:tabIdentifier];
    }

    [self resizeWindowForTab:[_tabView selectedTabViewItem] animated:NO];
}

- (void)save {
    for (ToolOption *option in _compilerOptions) {
        [option save];
    }
}


#pragma mark - Tool Versions

- (void)rubiesDidChange:(NSNotification *)notification {
    [self populateRubyVersions];
}

- (void)populateRubyVersions {
    NSMutableArray *rubyInstancesByIndex = [[NSMutableArray alloc] init];
    _rubyInstances = rubyInstancesByIndex;

    NSArray *systemInstances = [RubyRuntimeRepository sharedRubyManager].systemInstances;
    NSArray *customInstances = [RubyRuntimeRepository sharedRubyManager].customInstances;
    NSArray *containers = [RubyRuntimeRepository sharedRubyManager].containers;

//    NSMutableArray *titles = [_rubyInstances valueForKeyPath:@"title"];

    [_rubyVersionsPopUpButton removeAllItems];
    if (systemInstances.count > 0 || customInstances.count > 0 || containers.count > 0) {
        BOOL separatorRequired = NO;
        for (RubyInstance *instance in systemInstances) {
            [_rubyVersionsPopUpButton addItemWithTitle:instance.title];
            [rubyInstancesByIndex addObject:instance];
            separatorRequired = YES;
        }

        if (customInstances.count > 0) {
            if (separatorRequired) {
                [[_rubyVersionsPopUpButton menu] addItem:[NSMenuItem separatorItem]];
                [rubyInstancesByIndex addObject:[NSNull null]];
                separatorRequired = NO;
            }

            for (RubyInstance *instance in customInstances) {
                [_rubyVersionsPopUpButton addItemWithTitle:instance.title];
                [rubyInstancesByIndex addObject:instance];
                separatorRequired = YES;
            }
        }

        for (RuntimeContainer *container in containers) {
            if (separatorRequired) {
                [[_rubyVersionsPopUpButton menu] addItem:[NSMenuItem separatorItem]];
                [rubyInstancesByIndex addObject:[NSNull null]];
                separatorRequired = NO;
            }

            if (container.exposedToUser) {
                NSMenuItem *item = [[_rubyVersionsPopUpButton menu] addItemWithTitle:container.title action:nil keyEquivalent:@""];
                // item.enabled has no effect; see 'validateMenuItem:' below (which is why we set tag and target here)
                // item.enabled = NO;
                item.target = self;
                item.tag = 0xDEADBEEF;
                [rubyInstancesByIndex addObject:[NSNull null]];
            }

            if (container.instances.count > 0) {
                for (RubyInstance *instance in container.instances) {
                    [_rubyVersionsPopUpButton addItemWithTitle:instance.title];
                    [rubyInstancesByIndex addObject:instance];
                }
            } else {
                NSMenuItem *item = [[_rubyVersionsPopUpButton menu] addItemWithTitle:@"No rubies found." action:nil keyEquivalent:@""];
                item.target = self;
                item.tag = 0xDEADBEEF;
                [rubyInstancesByIndex addObject:[NSNull null]];
            }

            separatorRequired = YES;
        }

        if (separatorRequired) {
            [[_rubyVersionsPopUpButton menu] addItem:[NSMenuItem separatorItem]];
            [rubyInstancesByIndex addObject:[NSNull null]];
            separatorRequired = NO;
        }

        [[_rubyVersionsPopUpButton menu] addItemWithTitle:@"Configure Rubies..." action:@selector(manageRubies) keyEquivalent:@""];
        [rubyInstancesByIndex addObject:[NSNull null]];

        RuntimeInstance *selectedInstance = [[RubyRuntimeRepository sharedRubyManager] instanceIdentifiedBy:_project.rubyVersionIdentifier];
        NSInteger selectedIndex = [rubyInstancesByIndex indexOfObject:selectedInstance];

        // add if not found
        if (selectedIndex == NSNotFound) {
            selectedIndex = 0;

            [_rubyVersionsPopUpButton insertItemWithTitle:selectedInstance.title atIndex:selectedIndex];
            [rubyInstancesByIndex insertObject:selectedInstance atIndex:selectedIndex];
        }

        [_rubyVersionsPopUpButton setEnabled:YES];
        [_rubyVersionsPopUpButton selectItemAtIndex:selectedIndex];
    } else {
        if (_rubyVersionsPopUpButton.tag != 0x101) {
            _rubyVersionsPopUpButton.tag = 0x101;
            [_rubyVersionsPopUpButton addItemWithTitle:@"Loading…"];
            [_rubyVersionsPopUpButton setEnabled:NO];
        }
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.tag == 0xDEADBEEF)
        return NO;
    return YES;
}

- (void)restoreRubySelection {
    RuntimeInstance *selectedInstance = [[RubyRuntimeRepository sharedRubyManager] instanceIdentifiedBy:_project.rubyVersionIdentifier];
    NSInteger selectedIndex = [_rubyInstances indexOfObject:selectedInstance];
    if (selectedIndex != NSNotFound)
        [_rubyVersionsPopUpButton selectItemAtIndex:selectedIndex];
    else
        [self populateRubyVersions];
}

- (void)manageRubies {
    [self restoreRubySelection];
    [[PreferencesController sharedPreferencesController] showAddRubyInstancePage];
}

- (void)populateToolVersions {
    [self populateRubyVersions];
}

- (IBAction)nodeVersionsPopUpValueDidChange:(id)sender {
}

- (IBAction)rubyVersionsPopUpValueDidChange:(id)sender {
    NSInteger index = [_rubyVersionsPopUpButton indexOfSelectedItem];
    if (index < 0)
        return;

    RubyInstance *instance = [_rubyInstances objectAtIndex:index];
    if ([instance isKindOfClass:[RubyInstance class]]) {
        _project.rubyVersionIdentifier = instance.identifier;
        [self populateRubyVersions];
    } else {
        [self restoreRubySelection];
    }
}


#pragma mark - Tabs

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    [[NSUserDefaults standardUserDefaults] setObject:tabViewItem.identifier forKey:@"compilationOptionsTab"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self resizeWindowForTab:tabViewItem animated:YES];
}

- (compilation_settings_tab_t)enumForItem:(NSTabViewItem *)item {
    return ([[item identifier] isEqualToString:@"options"] ? compilation_settings_tab_options : compilation_settings_tab_paths);
}

- (compilation_settings_tab_t)currentTab {
    return [self enumForItem:_tabView.selectedTabViewItem];
}

- (void)resizeWindowForTab:(NSTabViewItem *)item animated:(BOOL)animated {
    CGFloat desiredHeight = ([self enumForItem:item] == compilation_settings_tab_options ? _compilerSettingsWindowHeight : _outputPathsWindowHeight);

    NSRect rect = self.window.frame;

    BOOL heightSet = NO;
    if ([self currentTab] == compilation_settings_tab_paths) {
        CGFloat height = [[NSUserDefaults standardUserDefaults] floatForKey:@"compilationOptions.height.paths"];
        if (height > 0.0) {
            rect.size.height = height;
            heightSet = YES;
        }
    }
    if (!heightSet) {
        rect.size.height += (desiredHeight - _tabView.frame.size.height);
    }

    CGFloat width = [[NSUserDefaults standardUserDefaults] floatForKey:@"compilationOptions.width"];
    if (width > 0.0) {
        rect.size.width = width;
    }
    
    if ([self currentTab] == compilation_settings_tab_paths && rect.size.height < self.window.minSize.height)
        rect.size.height = self.window.minSize.height;
    
    if (rect.size.width < self.window.minSize.width)
        rect.size.width = self.window.minSize.width;

    [self.window setFrame:rect display:YES animate:YES];
}

- (void)didDetectChange {
    [self updateOutputPathsTabData];
    [_pathTableView reloadData];
}



#pragma mark - Output Paths Tab

- (void)updateOutputPathsTabData {
    [_fileList release];
    _fileList = [[NSMutableArray alloc] init];

    FSTree *tree = _project.tree;
    for (Compiler *compiler in _project.compilersInUse) {
        CompilationOptions *options = [_project optionsForCompiler:compiler create:YES];

        for (NSString *path in [compiler pathsOfSourceFilesInTree:tree]) {
            FileCompilationOptions *fileOptions = [_project optionsForFileAtPath
              :path in:options];
            fileOptions.compiler = compiler;
            [_fileList addObject:fileOptions];
        }
    }

    [self updateOutputPathsButtonStates];
    [self updateApplyMaskButton];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _fileList.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    FileCompilationOptions *fileOptions = _fileList[row];
    output_paths_table_column_t column = str_static_array_index(output_paths_table_column_ids, [[tableColumn identifier] UTF8String]);
    BOOL imported = [_project isFileImported:fileOptions.sourcePath];
    if (column == output_paths_table_column_enable) {
        if (imported)
            return [NSNumber numberWithBool:NO];
        return [NSNumber numberWithBool:fileOptions.enabled];
    } else if (column == output_paths_table_column_source) {
        return fileOptions.sourcePath;
    } else if (column == output_paths_table_column_output) {
        if (imported)
            return @"(imported)";
        
        NSString *draftMask = [self draftFileNameMask];
        if (draftMask.length > 0 && [_bulkMaskEditingFiles containsObject:fileOptions])
            return [NSString stringWithFormat:@"%@ *", [fileOptions destinationDisplayPathForMask:draftMask]];
        else 
            return fileOptions.destinationPathForDisplay;
    } else {
        return nil;
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    FileCompilationOptions *fileOptions = _fileList[row];
    output_paths_table_column_t column = str_static_array_index(output_paths_table_column_ids, [[tableColumn identifier] UTF8String]);
    if (column == output_paths_table_column_enable) {
        fileOptions.enabled = [object boolValue];
    } else if (column == output_paths_table_column_source) {
    } else if (column == output_paths_table_column_output) {
        fileOptions.destinationPathForDisplay = [object stringByExpandingTildeInPath];
    } else {
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    FileCompilationOptions *fileOptions = _fileList[row];
    output_paths_table_column_t column = str_static_array_index(output_paths_table_column_ids, [[tableColumn identifier] UTF8String]);
    if (column == output_paths_table_column_enable || column == output_paths_table_column_output) {
        BOOL imported = [_project isFileImported:fileOptions.sourcePath];
        return !imported;
    }
    return YES;
}


- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    FileCompilationOptions *fileOptions = _fileList[row];
    output_paths_table_column_t column = str_static_array_index(output_paths_table_column_ids, [[tableColumn identifier] UTF8String]);
    BOOL imported = [_project isFileImported:fileOptions.sourcePath];
    if (column == output_paths_table_column_enable) {
        NSButtonCell *theCell = cell;
        [theCell setEnabled:!imported];
    } else if (column == output_paths_table_column_output) {
        NSTextFieldCell *theCell = cell;
        [theCell setEnabled:!imported];
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self endBulkMaskEditing];
    [self updateOutputPathsButtonStates];
}

#pragma mark -

- (NSArray *)selectedFileOptions {
    NSIndexSet *indexSet = [_pathTableView selectedRowIndexes];
    NSMutableArray *selection = [NSMutableArray array];
    for (NSUInteger currentIndex = [indexSet firstIndex]; currentIndex != NSNotFound; currentIndex = [indexSet indexGreaterThanIndex:currentIndex]) {
        [selection addObject:_fileList[currentIndex]];
    }

    // no selection => act on all files
    if ([selection count] == 0) {
        [selection addObjectsFromArray:_fileList];
    }

    return selection;
}

- (IBAction)chooseOutputDirectory:(id)sender {
    if (_fileList.count == 0) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"No files yet"];
        [alert setInformativeText:@"Before configuring an output directory, please create some source files first."];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }

    NSIndexSet *indexSet = [_pathTableView selectedRowIndexes];
    NSMutableArray *selection = [NSMutableArray array];
    for (NSUInteger currentIndex = [indexSet firstIndex]; currentIndex != NSNotFound; currentIndex = [indexSet indexGreaterThanIndex:currentIndex]) {
        [selection addObject:_fileList[currentIndex]];
    }

    NSString *initialPath = _project.path;
    NSString *common;
    if ([selection count] == 0) {
        [selection addObjectsFromArray:_fileList];

        NSString *common = [FileCompilationOptions commonOutputDirectoryFor:selection inProject:_project];
        if ([common isEqualToString:@"__NONE_SET__"]) {
            // do nothing
        } else if (common != nil) {
            initialPath = [_project.path stringByAppendingPathComponent:common];
        } else {
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setMessageText:@"Change all files?"];
            [alert setInformativeText:@"Files are currently configured with different output directories. Proceeding will set the SAME output directory for ALL files.\n\nYou can configure individual files by selecting them first."];
            [[alert addButtonWithTitle:@"Proceed"] setKeyEquivalent:@""];
            [alert addButtonWithTitle:@"Cancel"];
            if ([alert runModal] != NSAlertFirstButtonReturn) {
                return;
            }
        }
    } else if ([selection count] > 1) {
        NSString *common = [FileCompilationOptions commonOutputDirectoryFor:selection inProject:_project];
        if ([common isEqualToString:@"__NONE_SET__"]) {
            // do nothing
        } else if (common != nil) {
            initialPath = [_project.path stringByAppendingPathComponent:common];
        } else {
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setMessageText:@"Change all selected files?"];
            [alert setInformativeText:@"Selected files are currently configured with different output directories. Proceeding will set the same output directory for all selected files."];
            [[alert addButtonWithTitle:@"Proceed"] setKeyEquivalent:@""];
            [alert addButtonWithTitle:@"Cancel"];
            if ([alert runModal] != NSAlertFirstButtonReturn) {
                return;
            }
        }
    } else {
        common = ((FileCompilationOptions *)[selection objectAtIndex:0]).destinationDirectory;
        if (common != nil) {
            initialPath = [_project.path stringByAppendingPathComponent:common];
        }
    }

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setPrompt:@"Set Output Folder"];
    [openPanel setCanChooseFiles:NO];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:initialPath isDirectory:YES]];
    NSInteger result = [openPanel runModal];

    if (result == NSFileHandlingPanelOKButton) {
        NSURL *url = [openPanel URL];
        NSString *absolutePath = [url path];
        NSString *relativePath = [_project relativePathForPath:absolutePath];
        for (FileCompilationOptions *options in selection) {
            options.destinationDirectory = relativePath;
        }
        [_pathTableView reloadData];
    }
}

- (IBAction)chooseOutputFileName:(id)sender {
    NSArray *selection = [self selectedFileOptions];
    if ([selection count] != 1)
        return;

    FileCompilationOptions *fileOptions = [selection objectAtIndex:0];
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setNameFieldStringValue:fileOptions.destinationName];
    [savePanel setMessage:[NSString stringWithFormat:@"Choose an output file for %@", fileOptions.sourcePath]];
    [savePanel setDirectoryURL:[NSURL fileURLWithPath:(fileOptions.destinationDirectory.length > 0 ? [_project pathForRelativePath:fileOptions.destinationDirectory] : [[_project pathForRelativePath:fileOptions.sourcePath] stringByDeletingLastPathComponent]) isDirectory:YES]];
    NSInteger result = [savePanel runModal];
    
    if (result == NSFileHandlingPanelOKButton) {
        NSURL *url = [savePanel URL];
        NSString *absolutePath = [url path];
        NSString *relativePath = [_project relativePathForPath:absolutePath];
        
        fileOptions.destinationPath = relativePath;
        [_pathTableView reloadData];
    }
}

- (void)updateOutputPathsButtonStates {
    NSArray *selection = [self selectedFileOptions];

    _changeOutputFileButton.enabled = (selection.count == 1);
    
    [[_outputFileNameMask cell] setPlaceholderString:@"e.g. *.shtml"];
    if (selection.count == 0) {
        [_outputFileNameMask setStringValue:@""];
    } else {
        NSString *commonMask = [FileCompilationOptions commonDestinationNameMaskFor:selection inProject:_project];
        if (commonMask.length == 0) {
            [[_outputFileNameMask cell] setPlaceholderString:@"(multiple)"];
            [_outputFileNameMask setStringValue:@""];
        } else {
            [_outputFileNameMask setStringValue:commonMask];
        }
    }
}

- (void)startBulkMaskEditing {
    if (_bulkMaskEditingInProgress)
        return;
    _bulkMaskEditingInProgress = YES;
    _bulkMaskEditingFiles = [[NSSet alloc] initWithArray:[self selectedFileOptions]];
    
    _applyButton.keyEquivalent = @"";
    _applyOutputFileNameMaskButton.keyEquivalent = @"\r";

    [self updateApplyMaskButton];
}

- (void)endBulkMaskEditing {
    if (!_bulkMaskEditingInProgress)
        return;
    _bulkMaskEditingInProgress = NO;
    [_bulkMaskEditingFiles release], _bulkMaskEditingFiles = nil;
    [self.window setDefaultButtonCell:[_applyButton cell]];

    _applyOutputFileNameMaskButton.keyEquivalent = @"";
    _applyButton.keyEquivalent = @"\r";

    [_pathTableView reloadData];
    [self updateOutputPathsButtonStates];
    [self updateApplyMaskButton];
}

- (NSString *)draftFileNameMask {
    if (_bulkMaskEditingInProgress)
        return _outputFileNameMask.stringValue;
    else
        return nil;
}

- (void)updateApplyMaskButton {
    NSString *commonMask = [FileCompilationOptions commonDestinationNameMaskFor:[_bulkMaskEditingFiles allObjects] inProject:_project];
    _applyOutputFileNameMaskButton.enabled = [self draftFileNameMask].length > 0 && (commonMask.length == 0 || ![commonMask isEqualToString:[self draftFileNameMask]]);
}

- (void)controlTextDidBeginEditing:(NSNotification *)obj {
    NSLog(@"controlTextDidBeginEditing");
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    NSLog(@"controlTextDidEndEditing");
}

- (void)controlTextDidChange:(NSNotification *)obj {
    NSLog(@"controlTextDidChange");
    if (obj.object != _outputFileNameMask)
        return;

    [self startBulkMaskEditing];
    [self updateApplyMaskButton];
    [_pathTableView reloadData];
}

- (IBAction)applyFileNameMask:(id)sender {
    NSLog(@"applyFileNameMask");
    NSString *mask = _outputFileNameMask.stringValue;

    NSArray *selection = [self selectedFileOptions];
    for (FileCompilationOptions *fileOptions in selection) {
        fileOptions.destinationNameMask = mask;
    }

    [self endBulkMaskEditing];
}


#pragma mark - Settings Restore

- (void)windowDidResize:(NSNotification *)notification {
    if (notification.object == self.window) {
        NSSize size = self.window.frame.size;
        if ([self currentTab] == compilation_settings_tab_paths) {
            [[NSUserDefaults standardUserDefaults] setFloat:size.height forKey:@"compilationOptions.height.paths"];
        }
        [[NSUserDefaults standardUserDefaults] setFloat:size.width forKey:@"compilationOptions.width"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


@end
