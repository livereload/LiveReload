
#import "MonitoringSettingsWindowController.h"
@import LRCommons;

#import "Preferences.h"
#import "RegexKitLite.h"


@interface MonitoringSettingsWindowController () <NSTableViewDataSource, NSTableViewDelegate>
@end



@implementation MonitoringSettingsWindowController {
    ATCoalescedState _superAdvancedSavingCoalescense;
}

@synthesize builtInExtensionsLabelField=_builtInExtensionsLabelField;
@synthesize additionalExtensionsTextField = _additionalExtensionsTextField;
@synthesize disableLiveRefreshCheckBox = _disableLiveRefreshCheckBox;
@synthesize delayFullRefreshCheckBox = _delayFullRefreshCheckBox;
@synthesize fullRefreshDelayTextField = _fullRefreshDelayTextField;
@synthesize delayChangeProcessingButton = _delayChangeProcessingButton;
@synthesize changeProcessingDelayTextField = _changeProcessingDelayTextField;
@synthesize remoteServerWorkflowButton = _remoteServerWorkflowButton;
@synthesize excludedPathsTableView = _excludedPathsTableView;

- (void)windowDidLoad {
    [super windowDidLoad];
    [self observeNotification:NSTextDidChangeNotification withSelector:@selector(textDidChange:)];
    [self observeNotification:NSTextDidEndEditingNotification withSelector:@selector(textDidEndEditing:)];
}

- (void)dealloc {
    [self removeAllObservations];
}


#pragma mark - Actions

- (IBAction)showHelp:(id)sender {
    TenderShowArticle(@"");
}


#pragma mark - Model sync

- (void)renderFullPageRefreshDelay {
    if (_delayFullRefreshCheckBox.state == NSOnState) {
        _fullRefreshDelayTextField.stringValue = [NSString stringWithFormat:@"%.3f", _project.fullPageReloadDelay];
        [_fullRefreshDelayTextField setEnabled:YES];
    } else {
        _fullRefreshDelayTextField.stringValue = @"";
        [_fullRefreshDelayTextField setEnabled:NO];
    }
}

- (void)renderEventProcessingDelay {
    if (_delayChangeProcessingButton.state == NSOnState) {
        _changeProcessingDelayTextField.stringValue = [NSString stringWithFormat:@"%.3f", _project.eventProcessingDelay];
        [_changeProcessingDelayTextField setEnabled:YES];
    } else {
        _changeProcessingDelayTextField.stringValue = @"";
        [_changeProcessingDelayTextField setEnabled:NO];
    }
}

- (void)_renderSuperAdvancedOptions:(BOOL)rerenderOptions {
    if (rerenderOptions)
        _superAdvancedOptionsTextView.string = _project.superAdvancedOptionsString;
    _superAdvancedOptionsFeedbackTextField.stringValue = _project.superAdvancedOptionsFeedbackString;
}

- (void)_saveSuperAdvancedOptions:(BOOL)rerenderOptions {
    _project.superAdvancedOptionsString = _superAdvancedOptionsTextView.string;
    [self _renderSuperAdvancedOptions:rerenderOptions];
}

- (void)render {
    _builtInExtensionsLabelField.stringValue = [[[Preferences sharedPreferences].builtInExtensions sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@" "];
    _additionalExtensionsTextField.stringValue = [[Preferences sharedPreferences].additionalExtensions componentsJoinedByString:@" "];
    _disableLiveRefreshCheckBox.state = (_project.disableLiveRefresh ? NSOnState : NSOffState);
    _remoteServerWorkflowButton.state = (_project.enableRemoteServerWorkflow ? NSOnState : NSOffState);
    _delayFullRefreshCheckBox.state = (_project.fullPageReloadDelay > 0.001 ? NSOnState : NSOffState);
    _delayChangeProcessingButton.state = (_project.eventProcessingDelay > 0.001 ? NSOnState : NSOffState);
    [self renderFullPageRefreshDelay];
    [self renderEventProcessingDelay];
    [self _renderSuperAdvancedOptions:YES];
}

- (void)save {
    NSString *extensions = [[_additionalExtensionsTextField.stringValue stringByReplacingOccurrencesOfRegex:@"[, ]+" withString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [Preferences sharedPreferences].additionalExtensions = (extensions.length > 0 ? [extensions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : [NSArray array]);
    _project.fullPageReloadDelay = (_delayFullRefreshCheckBox.state == NSOnState ? _fullRefreshDelayTextField.doubleValue : 0.0);
    _project.eventProcessingDelay = (_delayChangeProcessingButton.state == NSOnState ? _changeProcessingDelayTextField.doubleValue : 0.0);
    [self _saveSuperAdvancedOptions:YES];
}


#pragma mark - Interim rules

- (IBAction)disableLiveRefreshCheckBoxClicked:(NSButton *)sender {
    _project.disableLiveRefresh = (_disableLiveRefreshCheckBox.state == NSOnState);
}

- (IBAction)delayFullRefreshCheckBoxClicked:(id)sender {
    [self renderFullPageRefreshDelay];
}

- (IBAction)delayEventProcessingClicked:(id)sender {
    [self renderEventProcessingDelay];
}

- (IBAction)enableRemoteServerWorkflowClicked:(id)sender {
    _project.enableRemoteServerWorkflow = (_remoteServerWorkflowButton.state == NSOnState);
}

#pragma mark - Excluded paths

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _project.excludedPaths.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return [_project.excludedPaths objectAtIndex:row];
}

- (IBAction)addExcludedPathClicked:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setPrompt:@"Choose a subfolder"];
    [openPanel setCanChooseFiles:NO];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:_project.path isDirectory:YES]];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [openPanel URL];
            NSString *path = [url path];
            if (![_project isPathInsideProject:path]) {
                [[NSAlert alertWithMessageText:@"Subfolder required" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Excluded folder must be a subfolder of the project."] runModal];
                return;
            }
            NSString *relativePath = [_project relativePathForPath:path];
            if (relativePath.length == 0) {
                [[NSAlert alertWithMessageText:@"Subfolder required" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Sorry, but excluding the project's root folder does not make sense."] runModal];
                return;
            }
            [_project addExcludedPath:relativePath];
            [_excludedPathsTableView reloadData];
        }
    }];
}

- (IBAction)removeExcludedPathClicked:(id)sender {
    NSInteger row = _excludedPathsTableView.selectedRow;
    if (row < 0)
        return;

    if (row >= (NSInteger)_project.excludedPaths.count)
        return;

    NSString *path = [_project.excludedPaths objectAtIndex:row];
    [_project removeExcludedPath:path];
    [_excludedPathsTableView reloadData];

    [_excludedPathsTableView deselectAll:nil];
}

- (void)textDidChange:(NSNotification *)notification {
    if (notification.object == _superAdvancedOptionsTextView) {
        AT_dispatch_coalesced(&_superAdvancedSavingCoalescense, 200, ^(dispatch_block_t done) {
            [self _saveSuperAdvancedOptions:NO];
            done();
        });
    }
}

- (void)textDidEndEditing:(NSNotification *)notification {
    if (notification.object == _superAdvancedOptionsTextView) {
        AT_dispatch_coalesced(&_superAdvancedSavingCoalescense, 200, ^(dispatch_block_t done) {
            [self _saveSuperAdvancedOptions:YES];
            done();
        });
    }
}

@end
