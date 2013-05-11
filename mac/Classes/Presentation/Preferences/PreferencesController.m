
#import "PreferencesController.h"
#import "MASPreferencesWindowController.h"
#import "RubyPreferencesViewController.h"


static PreferencesController *sharedPreferencesController;


@implementation PreferencesController {
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
        _rubiesPage = [[RubyPreferencesViewController alloc] init];
        _windowController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[_rubiesPage]];
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
