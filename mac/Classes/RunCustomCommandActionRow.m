
#import "RunCustomCommandActionRow.h"
#import "LiveReload-Swift-x.h"
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

    [self addConstraintsWithVisualFormat:@"|-indentL2-[checkbox(>=200)]-[filterPopUp(>=120)]-(>=buttonBarGapMin)-[optionsButton]-buttonGap-[removeButton]|" options:NSLayoutFormatAlignAllCenterY];
    [self addFullHeightConstraintsForSubview:self.filterPopUp];

//    [self alignView:self.checkbox toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.filterPopUp toColumnNamed:@"filter"];

    [self.checkbox bind:@"value" toObject:self.representedObject withKeyPath:@"enabled" options:nil];
}

- (void)loadOptionsIntoView:(LROptionsView *)container {
    _commandLineField = [NSTextField editableField];
    [_commandLineField makeHeightEqualTo:100];
    [container addOptionView:_commandLineField withLabel:NSLocalizedString(@"Command line:", nil) flags:LROptionsViewFlagsLabelAlignmentTop];

    [_commandLineField bind:@"value" toObject:self.representedObject withKeyPath:@"command" options:nil];
}

- (void)updateContent {
    [super updateContent];

    CustomCommandRule *action = self.representedObject;
    [self.checkbox setTitle:action.label];
}

- (void)updateFilterOptions {
    [self updateFilterOptionsPopUp:self.filterPopUp selectedOption:self.action.inputFilterOption];
}

- (IBAction)filterOptionSelected:(NSPopUpButton *)sender {
    FilterOption *filterOption = sender.selectedItem.representedObject;
    self.action.inputFilterOption = filterOption;
}

+ (NSArray *)representedObjectKeyPathsToObserve {
    return @[@"command", @"inputFilterOption"];
}

@end
