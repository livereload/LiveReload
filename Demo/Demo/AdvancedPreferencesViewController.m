
#import "AdvancedPreferencesViewController.h"

@implementation AdvancedPreferencesViewController

@synthesize textField = _textField;
@synthesize tableView = _tableView;

#pragma mark -

- (id)init
{
    return [super initWithNibName:@"AdvancedPreferencesView" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameAdvanced];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Advanced", @"Toolbar item name for the Advanced preference pane");
}

- (NSView *)initialKeyView
{
    NSInteger focusedControlIndex = [[NSApp valueForKeyPath:@"delegate.focusedAdvancedControlIndex"] integerValue];
    return (focusedControlIndex == 0 ? self.textField : self.tableView);
}

@end
