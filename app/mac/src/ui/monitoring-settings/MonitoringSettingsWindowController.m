
#import "MonitoringSettingsWindowController.h"
#include "nodeapp.h"


@implementation MonitoringSettingsWindowController {
    IBOutlet NSButton *applyButton;
    IBOutlet NSButton *addExcludedPathButton;
    IBOutlet NSButton *removeExcludedPathButton;
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


- (void)chooseFolderToExclude:(NSDictionary *)arg {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:YES];
    [openPanel setPrompt:@"Choose folder"];
    [openPanel setCanChooseFiles:NO];
    [openPanel setTreatsFilePackagesAsDirectories:YES];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        NSString *callback = [arg objectForKey:@"callback"];
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *url = [openPanel URL];
            NSString *path = [url path];
            NodeAppRpcInvokeAndDisposeCallback(callback, path);
        } else {
            NodeAppRpcInvokeAndDisposeCallback(callback, nil);
        }
    }];
}

@end
