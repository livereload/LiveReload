@import LRCommons;

#import "FilterRuleRow.h"


@implementation FilterRuleRow

- (void)loadContent {
    [super loadContent];

    self.filterPopUp = [[[[NSPopUpButton popUpButton] withBezelStyle:NSRoundRectBezelStyle] withTarget:self action:@selector(filterOptionSelected:)] addedToView:self];
    [[self.filterPopUp cell] setLineBreakMode:NSLineBreakByTruncatingHead];
    [self.filterPopUp setContentCompressionResistancePriority:450 forOrientation:NSLayoutConstraintOrientationHorizontal];

    [self addConstraintsWithVisualFormat:@"|-indentL2-[checkbox(>=200)]-[filterPopUp(>=120)]-(>=buttonBarGapMin)-[optionsButton]-buttonGap-[removeButton]|" options:NSLayoutFormatAlignAllCenterY];
    [self addFullHeightConstraintsForSubview:self.filterPopUp];

    //    [self alignView:self.checkbox toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.filterPopUp toColumnNamed:@"from"];
    //    [self alignView:self.toLabel toColumnNamed:@"to"];

    [self.checkbox bind:@"value" toObject:self.representedObject withKeyPath:@"enabled" options:nil];
}

- (void)updateContent {
    [super updateContent];
    self.checkbox.title = self.rule.label;
}

- (void)updateFilterOptions {
    [self updateFilterOptionsPopUp:self.filterPopUp selectedOption:self.rule.inputFilterOption];
}

- (IBAction)filterOptionSelected:(NSPopUpButton *)sender {
    FilterOption *filterOption = sender.selectedItem.representedObject;
    self.rule.inputFilterOption = filterOption;
}

+ (NSArray *)representedObjectKeyPathsToObserve {
    return @[@"inputFilterOption"];
}

- (void)loadOptionsIntoView:(LROptionsView *)container {
    for (Option *option in [self.rule createOptions]) {
        OptionController *controller = [OptionController controllerForOption:option];
        if (controller) {
            [container addOption:controller];
        }
    }
}

@end
