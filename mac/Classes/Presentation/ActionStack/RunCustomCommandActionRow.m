
#import "RunCustomCommandActionRow.h"
#import "CustomCommandAction.h"
#import "Action.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"
#import "Project.h"
#import "FilterOption.h"
#import "ATAttributedStringAdditions.h"


@interface RunCustomCommandActionRow ()

//@property(nonatomic, strong) NSTextField *runLabel;
//@property(nonatomic, strong) NSTextField *commandField;
@property(nonatomic, strong) NSPopUpButton *filterPopUp;

@property(nonatomic, strong) NSTextField *commandLineField;

@end


@implementation RunCustomCommandActionRow

- (void)loadContent {
    [super loadContent];

//    self.runLabel = [[NSTextField staticLabelWithString:@"Run"] addedToView:self];
//    _commandField = [[NSTextField editableField] addedToView:self];
    self.filterPopUp = [[[[NSPopUpButton popUpButton] withBezelStyle:NSRoundRectBezelStyle] withTarget:self action:@selector(filterOptionSelected:)] addedToView:self];
    [self.filterPopUp addItemWithTitle:@"any file"];

    [self addConstraintsWithVisualFormat:@"|-indentL2-[checkbox(>=200)]-[filterPopUp(>=120)]-(>=buttonBarGapMin)-[optionsButton]-buttonGap-[removeButton]|" options:NSLayoutFormatAlignAllCenterY];
    [self addFullHeightConstraintsForSubview:self.filterPopUp];

//    [self alignView:self.checkbox toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.filterPopUp toColumnNamed:@"filter"];

    [self.checkbox bind:@"value" toObject:self.representedObject withKeyPath:@"enabled" options:nil];
}

- (void)loadOptionsIntoView:(LROptionsView *)container {
    _commandLineField = [NSTextField editableField];
    [_commandLineField makeHeightEqualTo:100];
    [container addOptionView:_commandLineField label:NSLocalizedString(@"Command line:", nil) flags:LROptionsViewFlagsLabelAlignmentTop];

    [_commandLineField bind:@"value" toObject:self.representedObject withKeyPath:@"command" options:nil];
}

- (void)updateContent {
    CustomCommandAction *action = self.representedObject;
    NSString *command = action.singleLineCommand;

    [self.checkbox setTitle:(command.length > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Run %@", nil), command] : NSLocalizedString(@"Run custom command", nil))];

    [self updateFilterOptions];
}

- (void)updateFilterOptions {
    [self updateFilterOptionsPopUp:self.filterPopUp selectedOption:self.action.inputFilterOption];
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

    [self.filterPopUp selectItem:selectedItem];
}

- (IBAction)filterOptionSelected:(id)sender {
    FilterOption *filterOption = self.filterPopUp.selectedItem.representedObject;
    self.action.inputFilterOption = filterOption;
}

+ (NSArray *)representedObjectKeyPathsToObserve {
    return @[@"command", @"inputFilterOption"];
}

@end
