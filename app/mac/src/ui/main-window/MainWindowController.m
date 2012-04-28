
#import "MainWindowController.h"


@implementation MainWindowController

@synthesize welcomePane = _welcomePane;
@synthesize welcomeMessageField = _welcomeMessageField;
@synthesize statusTextField = _statusTextField;
@synthesize terminalButton = _terminalButton;
@synthesize paneBorderBox = _paneBorderBox;
@synthesize panePlaceholder = _panePlaceholder;
@synthesize projectPane = _projectPane;
@synthesize titleBarSideView = _titleBarSideView;
@synthesize versionMenuItem = _versionMenuItem;
@synthesize openAtLoginMenuItem = _openAtLoginMenuItem;
@synthesize projectOutlineView = _projectOutlineView;
@synthesize addProjectButton = _addProjectButton;
@synthesize removeProjectButton = _removeProjectButton;
@synthesize gettingStartedView = _gettingStartedView;
@synthesize gettingStartedIconView = _gettingStartedIconView;
@synthesize gettingStartedLabelField = _gettingStartedLabelField;
@synthesize iconView = _iconView;
@synthesize nameTextField = _nameTextField;
@synthesize pathTextField = _pathTextField;
@synthesize snippetLabelField = _snippetLabelField;
@synthesize snippetBodyTextField = _snippetBodyTextField;
@synthesize monitoringSummaryLabelField = _monitoringSummaryLabelField;
@synthesize compilerEnabledCheckBox = _compilerEnabledCheckBox;
@synthesize postProcessingEnabledCheckBox = _postProcessingEnabledCheckBox;
@synthesize availableCompilersLabel = _availableCompilersLabel;


- (void)windowDidLoad {
    [super windowDidLoad];

    // add frame controls
    NSView *themeFrame = [self.window.contentView superview];
    CGFloat titleBarHeight = [self.window frame].size.height - [self.window contentRectForFrameRect:[self.window frame]].size.height - 2;
    _titleBarSideView.frame = NSMakeRect(themeFrame.frame.size.width - _titleBarSideView.frame.size.width - 16, themeFrame.frame.size.height - titleBarHeight + (titleBarHeight - _titleBarSideView.frame.size.height) / 2, _titleBarSideView.frame.size.width, _titleBarSideView.frame.size.height);
    [themeFrame addSubview:_titleBarSideView];
}

// Select All for the edit control
- (void)window:(NSWindow *)window didChangeFirstResponder:(NSResponder *)responder {
    if (responder == _snippetBodyTextField) {
        // doing this immediately does not work because NSTextField needs time to make its field editor the first responder
        // http://stackoverflow.com/questions/2195704/selecttext-of-nstextfield-on-focus
        [_snippetBodyTextField performSelector:@selector(selectText:) withObject:nil afterDelay:0.0];

        // not trying to copy automatically because this will require a stupid UI ("copied!" label),
        // and I physically miss pressing Command-C anyway
    }
}

@end
