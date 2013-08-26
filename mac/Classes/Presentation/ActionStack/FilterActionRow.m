
#import "FilterActionRow.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"

@implementation FilterActionRow

- (void)loadContent {
    [super loadContent];

    self.filterPopUp = [[[[NSPopUpButton popUpButton] withBezelStyle:NSRoundRectBezelStyle] withTarget:self action:@selector(filterOptionSelected:)] addedToView:self];

    [self addConstraintsWithVisualFormat:@"|-indentL2-[checkbox(>=200)]-[filterPopUp(>=120)]-(>=buttonBarGapMin)-[optionsButton]-buttonGap-[removeButton]|" options:NSLayoutFormatAlignAllCenterY];
    [self addFullHeightConstraintsForSubview:self.filterPopUp];

    //    [self alignView:self.checkbox toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.filterPopUp toColumnNamed:@"from"];
    //    [self alignView:self.toLabel toColumnNamed:@"to"];

    [self.checkbox bind:@"value" toObject:self.representedObject withKeyPath:@"enabled" options:nil];
}

- (void)updateContent {
    [super updateContent];
    self.checkbox.title = self.action.label;
}

- (void)updateFilterOptions {
    [self updateFilterOptionsPopUp:self.filterPopUp selectedOption:self.action.inputFilterOption];
}

- (IBAction)filterOptionSelected:(NSPopUpButton *)sender {
    FilterOption *filterOption = sender.selectedItem.representedObject;
    self.action.inputFilterOption = filterOption;
}

@end
