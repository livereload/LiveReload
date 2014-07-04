
#import "PreferencesController.h"
#import "MASPreferencesWindowController.h"
#import "GeneralPreferencesViewController.h"
#import "RubyPreferencesViewController.h"


static PreferencesController *sharedPreferencesController;


@implementation PreferencesController {
    GeneralPreferencesViewController *_generalPage;
    RubyPreferencesViewController *_rubiesPage;
    MASPreferencesWindowController *_windowController;
}

+ (PreferencesController *)sharedPreferencesController {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPreferencesController = [[PreferencesController alloc] init];
    });
    return sharedPreferencesController;
}

- (id)init
{
    self = [super init];
    if (self) {
        _generalPage = [[GeneralPreferencesViewController alloc] init];
        _rubiesPage = [[RubyPreferencesViewController alloc] init];
        _windowController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[_generalPage, _rubiesPage]];
    }
    return self;
}

- (void)show {
    [_windowController showWindow:self];
}

- (void)showOnPage:(NSViewController *)page {
    [self show];
    [_windowController selectControllerAtIndex:[_windowController.viewControllers indexOfObject:page]];
}

- (void)showAddRubyInstancePage {
    [self showOnPage:_rubiesPage];
}

@end
