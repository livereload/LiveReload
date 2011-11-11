
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

- (void)render {
    _builtInExtensionsLabelField.stringValue = [[[Preferences sharedPreferences].builtInExtensions sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@" "];
    _additionalExtensionsTextField.stringValue = [[Preferences sharedPreferences].additionalExtensions componentsJoinedByString:@" "];
}

- (void)save {
    NSString *extensions = [[_additionalExtensionsTextField.stringValue stringByReplacingOccurrencesOfRegex:@"[, ]+" withString:@" "] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [Preferences sharedPreferences].additionalExtensions = (extensions.length > 0 ? [extensions componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] : [NSArray array]);
}


#pragma mark - Interim actions

- (IBAction)disableLiveRefreshCheckBoxClicked:(NSButton *)sender {
}

- (IBAction)delayFullRefreshCheckBoxClicked:(id)sender {
}


@end
