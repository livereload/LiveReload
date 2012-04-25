
#import "MainWindowController.h"

static MainWindowController *me;


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

- (id)init {
    self = [super initWithWindowNibName:@"MainWindow"];
    if (self) {
        _folderImage = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)] retain];
        [_folderImage setSize:NSMakeSize(16,16)];

        me = self;
    }
    return self;
}

- (NSShadow *)subtleWhiteShadow {
    static NSShadow *shadow = nil;
    if (shadow == nil) {
        shadow = [[NSShadow alloc] init];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:0.33]];
    }
    return shadow;
}

- (NSColor *)headerLabelColor {
    return [NSColor colorWithCalibratedRed:58.0/255 green:61.0/255 blue:64.0/255 alpha:1.0];
}

- (NSParagraphStyle *)paragraphStyleForLabel:(NSControl *)label {
    NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [style setAlignment:label.alignment];
    return style;
}

- (void)styleLabel:(NSControl *)label color:(NSColor *)color shadow:(NSShadow *)shadow text:(NSString *)text {
    [label setAttributedStringValue:[[[NSAttributedString alloc] initWithString:text attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]] autorelease]];
}

- (void)styleLabel:(NSControl *)label color:(NSColor *)color shadow:(NSShadow *)shadow {
    [self styleLabel:label color:color shadow:shadow text:label.stringValue];
}

- (void)stylePartialHyperlink:(NSTextField *)label to:(NSURL *)url color:(NSColor *)color linkColor:(NSColor *)linkColor shadow:(NSShadow *)shadow {
    // both are needed, otherwise hyperlink won't accept mousedown
    [label setAllowsEditingTextAttributes:YES];
    [label setSelectable:YES];

    NSString *string = label.stringValue;
    NSRange range = [string rangeOfString:@"_["];
    NSAssert(range.length > 0, @"Partial hyperlink must contain _[ marker");
    NSString *prefix = [string substringToIndex:range.location];
    string = [string substringFromIndex:range.location + range.length];

    range = [string rangeOfString:@"]_"];
    NSAssert(range.length > 0, @"Partial hyperlink must contain ]_ marker");
    NSString *link = [string substringToIndex:range.location];
    NSString *suffix = [string substringFromIndex:range.location + range.length];

    NSMutableAttributedString *as = [[[NSMutableAttributedString alloc] init] autorelease];

    if (shadow == nil) {
        shadow = [[[NSShadow alloc] init] autorelease];
    }

    [as appendAttributedString:[[[NSAttributedString alloc] initWithString:prefix attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]] autorelease]];

    [as appendAttributedString:[[[NSAttributedString alloc] initWithString:link attributes:[NSDictionary dictionaryWithObjectsAndKeys:linkColor, NSForegroundColorAttributeName, [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, url, NSLinkAttributeName, label.font, NSFontAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, nil]] autorelease]];

    [as appendAttributedString:[[[NSAttributedString alloc] initWithString:suffix attributes:[NSDictionary dictionaryWithObjectsAndKeys:color, NSForegroundColorAttributeName, shadow, NSShadowAttributeName, [self paragraphStyleForLabel:label], NSParagraphStyleAttributeName, label.font, NSFontAttributeName, nil]] autorelease]];

    label.attributedStringValue = as;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    // add frame controls
    NSView *themeFrame = [self.window.contentView superview];
    CGFloat titleBarHeight = [self.window frame].size.height - [self.window contentRectForFrameRect:[self.window frame]].size.height - 2;
    _titleBarSideView.frame = NSMakeRect(themeFrame.frame.size.width - _titleBarSideView.frame.size.width - 16, themeFrame.frame.size.height - titleBarHeight + (titleBarHeight - _titleBarSideView.frame.size.height) / 2, _titleBarSideView.frame.size.width, _titleBarSideView.frame.size.height);
    [themeFrame addSubview:_titleBarSideView];

    [_projectOutlineView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [_projectOutlineView setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationLink forLocal:NO];

    [_nameTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_pathTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_statusTextField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_addProjectButton.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_removeProjectButton.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_gettingStartedIconView.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_gettingStartedLabelField.cell setBackgroundStyle:NSBackgroundStyleRaised];
    [_terminalButton.cell setBackgroundStyle:NSBackgroundStyleRaised];

    [self stylePartialHyperlink:_snippetLabelField to:[NSURL URLWithString:@"http://help.livereload.com/kb/general-use/browser-extensions"] color:[NSColor blackColor] linkColor:[NSColor colorWithCalibratedRed:0 green:10/255.0 blue:137/255.0 alpha:1.0] shadow:nil];;
}

- (IBAction)showWindow:(id)sender {
    [super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification {
    if (_projectSettingsSheetController && [_projectSettingsSheetController isWindowLoaded]) {
        [NSApp endSheet:[_projectSettingsSheetController window]];
    }
}


#pragma mark - Project Pane

- (void)window:(NSWindow *)window didChangeFirstResponder:(NSResponder *)responder {
    if (responder == _snippetBodyTextField) {
        // doing this immediately does not work because NSTextField needs time to make its field editor the first responder
        // http://stackoverflow.com/questions/2195704/selecttext-of-nstextfield-on-focus
        [_snippetBodyTextField performSelector:@selector(selectText:) withObject:nil afterDelay:0.0];

        // not trying to copy automatically because this will require a stupid UI ("copied!" label),
        // and I physically miss pressing Command-C anyway
    }
}


#pragma mark - Contextual menu
//
//- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
//    if (menuItem.target == self) {
//        if (menuItem.action == @selector(doNothingOnShowAs:)) {
//            menuItem.enabled = NO;
//            if (_selectedProject == nil) {
//                menuItem.title = @"No project selected";
//            } else {
//                menuItem.title = @"Show As:";
//            }
//            return NO;
//        } else if (menuItem.action == @selector(useProposedProjectName:)) {
//            NSInteger numberOfPathComponentsToUseAsName = menuItem.tag - 1001 + 1;
//            NSString *name = [_selectedProject proposedNameAtIndex:numberOfPathComponentsToUseAsName - 1];
//            if (name) {
//                menuItem.title = name;
//                menuItem.hidden = NO;
//            } else {
//                menuItem.hidden = YES;
//            }
//            menuItem.state = (_selectedProject.numberOfPathComponentsToUseAsName == numberOfPathComponentsToUseAsName ? NSOnState : NSOffState);
//        } else if (menuItem.action == @selector(usePreviouslySetCustomProjectName:)) {
//            menuItem.title = _selectedProject.customName ?: @"";
//            menuItem.hidden = (_selectedProject.customName.length == 0);
//            menuItem.state = (_selectedProject.numberOfPathComponentsToUseAsName == ProjectUseCustomName ? NSOnState : NSOffState);
//        } else if (menuItem.tag >= 500 && menuItem.tag <= 999) {
//            menuItem.hidden = (_selectedProject == nil);
//        }
//        return YES;
//    }
//    return NO;
//}
//
//- (IBAction)useNewCustomProjectName:(NSMenuItem *)sender {
//    NSInteger row = [_projectOutlineView rowForItem:_selectedProject];
//    [_projectOutlineView editColumn:0 row:row withEvent:[NSApp currentEvent] select:YES];
//}
//
//- (IBAction)usePreviouslySetCustomProjectName:(NSMenuItem *)sender {
//    if (_selectedProject.customName.length > 0) {
//        _selectedProject.numberOfPathComponentsToUseAsName = ProjectUseCustomName;
//        [_projectOutlineView reloadData];
//    }
//}
//
//- (IBAction)useProposedProjectName:(NSMenuItem *)sender {
//    _selectedProject.numberOfPathComponentsToUseAsName = sender.tag - 1000;
//    [_projectOutlineView reloadData];
//}
//
//- (IBAction)doNothingOnShowAs:(id)sender {
//}


#pragma mark - Settings menu

- (void)updateItemStates {
//    _openAtLoginMenuItem.state = ([LoginItemController sharedController].loginItemEnabled ? NSOnState : NSOffState);
//
//    AppVisibilityMode visibilityMode = [DockIcon currentDockIcon].visibilityMode;
//    [_showInDockMenuItem setState:(visibilityMode == AppVisibilityModeDock ? NSOnState : NSOffState)];
//    [_showInMenuBarMenuItem setState:(visibilityMode == AppVisibilityModeMenuBar ? NSOnState : NSOffState)];
//    [_showNowhereMenuItem setState:(visibilityMode == AppVisibilityModeNone ? NSOnState : NSOffState)];
}

- (IBAction)toggleOpenAtLogin:(id)sender {
//    [LoginItemController sharedController].loginItemEnabled = ![LoginItemController sharedController].loginItemEnabled;
//    [self updateItemStates];
}

- (IBAction)toggleVisibilityMode:(NSMenuItem *)sender {
//    [DockIcon currentDockIcon].visibilityMode = (AppVisibilityMode)sender.tag;
//    [self updateItemStates];
}

- (IBAction)performQuit:(id)sender {
    [NSApp terminate:self];
}


#pragma mark - Help menu

- (IBAction)performHelp:(id)sender {
//    TenderDisplayHelp();
}

- (IBAction)performKeyboardHelp:(id)sender {
//    TenderShowArticle(@"general-use/keyboard-shortcuts");
}

- (IBAction)performWebSite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://livereload.com/"]];
}

- (IBAction)performReportProblem:(id)sender {
//    TenderStartDiscussionIn(@"problems");
}

- (IBAction)performAskQuestion:(id)sender {
//    TenderStartDiscussionIn(@"questions");
}

- (IBAction)performSuggest:(id)sender {
//    TenderStartDiscussionIn(@"suggestions");
}

@end
