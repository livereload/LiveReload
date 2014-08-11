@import LRCommons;

#import "BaseRuleRow.h"
#import "OptionsRow.h"
#import "Project.h"


static void *BaseActionRow_Project_FilterOptions_Context = "BaseActionRow_Project_FilterOptions_Context";


@implementation BaseRuleRow {
    OptionsRow *_optionsRow;
}

- (void)loadContent {
//    [self.checkbox makeWidthLessThanOrEqualTo:[self.metrics[@"actionWidthMax"] doubleValue]];

    // more than 250 to make it actually expand, but less than 500 to avoid affecting the window size
    [self.checkbox setContentCompressionResistancePriority:400 forOrientation:NSLayoutConstraintOrientationHorizontal];

    self.topMargin = self.bottomMargin = 8;

    self.childRows = @[self.optionsRow];
}

- (NSButton *)checkbox {
    if (!_checkbox) {
        _checkbox = [[NSButton buttonWithTitle:@"" type:NSSwitchButton bezelStyle:NSRoundRectBezelStyle] addedToView:self];
        [[_checkbox cell] setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return _checkbox;
}

- (NSButton *)optionsButton {
    if (!_optionsButton) {
        _optionsButton = [[[NSButton buttonWithImageNamed:@"LROptionsTemplate" type:NSPushOnPushOffButton bezelStyle:NSRecessedBezelStyle] withTarget:self action:@selector(optionsClicked:)] addedToView:self];
    }
    return _optionsButton;
}

- (NSButton *)removeButton {
    return _removeButton ?: (_removeButton = [[[NSButton buttonWithImageNamed:@"NSRemoveTemplate" type:NSMomentaryPushInButton bezelStyle:NSRecessedBezelStyle] withTarget:self action:@selector(removeClicked:)] addedToView:self]);
}

- (OptionsRow *)optionsRow {
    if (!_optionsRow) {
        _optionsRow = [OptionsRow rowWithRepresentedObject:self.representedObject metrics:self.metrics userInfo:nil delegate:self];
        _optionsRow.collapsed = YES;

        __weak BaseRuleRow *myself = self;
        _optionsRow.loadContentBlock = ^{
            [myself _loadOptions];
        };
    }
    return _optionsRow;
}

- (IBAction)optionsClicked:(id)sender {
    BOOL collapse = (self.optionsButton.state != NSOnState);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.optionsRow setCollapsed:collapse animated:YES];
    });
}

- (IBAction)removeClicked:(id)sender {
    [self.delegate removeActionClicked:self.representedObject];
}

- (void)_loadOptions {
    [self loadOptionsIntoView:_optionsRow.optionsView];
}

- (void)loadOptionsIntoView:(LROptionsView *)container {
}

- (void)setDelegate:(id)delegate {
    NSAssert([delegate conformsToProtocol:@protocol(BaseActionRowDelegate)], @"Delegate must conform to BaseActionRowDelegate");
    [super setDelegate:delegate];
}

- (void)didUpdateUserInfo {
    self.project = self.userInfo[@"project"];
}

- (void)setProject:(Project *)project {
    if (_project != project) {
        [self stopObservingProject];
        _project = project;
        [self startObservingProject];
    }
}

- (Rule *)rule {
    return self.representedObject;
}

- (void)stopObservingProject {
    [self.project removeObserver:self forKeyPath:@"filterOptions" context:BaseActionRow_Project_FilterOptions_Context];
}

- (void)startObservingProject {
    [self.project addObserver:self forKeyPath:@"filterOptions" options:0 context:BaseActionRow_Project_FilterOptions_Context];
}

- (void)filterOptionsDidChange {
    [self updateFilterOptions];
}

- (void)updateContent {
    [self updateFilterOptions];
}

- (void)updateFilterOptions {
}

- (void)updateFilterOptionsPopUp:(NSPopUpButton *)popUp selectedOption:(FilterOption *)selectedOption {
    NSMenu *menu = popUp.menu;
    [menu removeAllItems];

    NSMenuItem *selectedItem = nil;

    NSArray *filterOptions = self.project.pathOptions;
    for (FilterOption *filterOption in filterOptions) {
        NSMenuItem *item = [menu addItemWithTitle:filterOption.displayName action:NULL keyEquivalent:@""];
        item.representedObject = filterOption;

        if (selectedOption && [filterOption isEqualToFilterOption:selectedOption])
            selectedItem = item;
    }

    if (!selectedItem && selectedOption) {
        selectedItem = [menu addItemWithTitle:selectedOption.displayName action:NULL keyEquivalent:@""];
        selectedItem.representedObject = selectedOption;
        selectedItem.attributedTitle = [NSAttributedString AT_attributedStringWithPrimaryString:selectedOption.displayName secondaryString:NSLocalizedString(@" (missing)", @"Missing suffix for pop ups") primaryStyle:@{NSFontAttributeName:[NSFont menuFontOfSize:0]} secondaryStyle:@{NSForegroundColorAttributeName:[NSColor disabledControlTextColor], NSFontAttributeName:[NSFont menuFontOfSize:10]}];
    }

    [popUp selectItem:selectedItem];

    NSMenuItem *item;
    [menu addItem:[NSMenuItem separatorItem]];
    item = [menu addItemWithTitle:@"recursive" action:NULL keyEquivalent:@""];
    [item setState:NSOnState];
    item = [menu addItemWithTitle:@"flatten" action:NULL keyEquivalent:@""];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == BaseActionRow_Project_FilterOptions_Context) {
        [self filterOptionsDidChange];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
