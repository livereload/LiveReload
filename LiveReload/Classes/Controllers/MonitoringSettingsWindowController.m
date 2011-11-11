
#import "MonitoringSettingsWindowController.h"

#import "Preferences.h"
#import "RegexKitLite.h"


@implementation MonitoringSettingsWindowController

@synthesize builtInExtensionsLabelField=_builtInExtensionsLabelField;
@synthesize additionalExtensionsTextField = _additionalExtensionsTextField;
@synthesize disableLiveRefreshCheckBox = _disableLiveRefreshCheckBox;
@synthesize delayFullRefreshCheckBox = _delayFullRefreshCheckBox;
@synthesize fullRefreshDelayTextField = _fullRefreshDelayTextField;

- (void)windowDidLoad {
    [super windowDidLoad];
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

- (void)render {
    _builtInExtensionsLabelField.stringValue = [[[Preferences sharedPreferences].builtInExtensions sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@" "];
    _additionalExtensionsTextField.stringValue = [[Preferences sharedPreferences].additionalExtensions componentsJoinedByString:@" "];
    _disableLiveRefreshCheckBox.state = (_project.disableLiveRefresh ? NSOnState : NSOffState);
    _delayFullRefreshCheckBox.state = (_project.fullPageReloadDelay > 0.001 ? NSOnState : NSOffState);
    [self renderFullPageRefreshDelay];
}

- (void)save {
    NSString *extensions = [[_additionalExtensionsTextField.stringValue stringByReplacingOccurrencesOfRegex:@"[, ]+" withString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [Preferences sharedPreferences].additionalExtensions = (extensions.length > 0 ? [extensions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : [NSArray array]);
    _project.fullPageReloadDelay = (_delayFullRefreshCheckBox.state == NSOnState ? _fullRefreshDelayTextField.doubleValue : 0.0);
}


#pragma mark - Interim actions

- (IBAction)disableLiveRefreshCheckBoxClicked:(NSButton *)sender {
    _project.disableLiveRefresh = (_disableLiveRefreshCheckBox.state == NSOnState);
}

- (IBAction)delayFullRefreshCheckBoxClicked:(id)sender {
    [self renderFullPageRefreshDelay];
}


@end
