
#import "CompileFileActionRow.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"


@implementation CompileFileActionRow

- (void)loadContent {
    [super loadContent];

    self.sourcePopUp = [[[[NSPopUpButton popUpButton] withBezelStyle:NSRoundRectBezelStyle] withTarget:self action:@selector(sourceOptionSelected:)] addedToView:self];

    [self addConstraintsWithVisualFormat:@"|-indentL2-[checkbox(>=200)]-[sourcePopUp(>=120)]-(>=buttonBarGapMin)-[optionsButton]-buttonGap-[removeButton]|" options:NSLayoutFormatAlignAllCenterY];
    [self addFullHeightConstraintsForSubview:self.sourcePopUp];

    //    [self alignView:self.checkbox toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.sourcePopUp toColumnNamed:@"from"];
    //    [self alignView:self.toLabel toColumnNamed:@"to"];

    [self.checkbox bind:@"value" toObject:self.representedObject withKeyPath:@"enabled" options:nil];
}

- (void)updateContent {
    [super updateContent];
    self.checkbox.title = self.action.label;
}

- (void)updateFilterOptions {
    [self updateFilterOptionsPopUp:self.sourcePopUp selectedOption:self.action.inputFilterOption];
}

- (IBAction)sourceOptionSelected:(NSPopUpButton *)sender {
    FilterOption *filterOption = sender.selectedItem.representedObject;
    self.action.inputFilterOption = filterOption;
}

@end
