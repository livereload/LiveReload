
#import "RunCustomCommandActionRow.h"
#import "Action.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"


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
    self.filterPopUp = [[[NSPopUpButton popUpButton] withBezelStyle:NSRoundRectBezelStyle] addedToView:self];

    [self addConstraintsWithVisualFormat:@"|-indentL2-[checkbox]-[filterPopUp(>=120)]-(>=buttonBarGapMin)-[optionsButton]-buttonGap-[removeButton]|" options:NSLayoutFormatAlignAllCenterY];
    [self addFullHeightConstraintsForSubview:self.filterPopUp];

    [self alignView:self.checkbox toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.filterPopUp toColumnNamed:@"filter"];
}

- (void)loadOptionsIntoView:(LROptionsView *)container {
    _commandLineField = [NSTextField editableField];
    [_commandLineField makeHeightEqualTo:100];
    [container addOptionView:_commandLineField label:NSLocalizedString(@"Command line:", nil) flags:LROptionsViewFlagsLabelAlignmentTop];
    [_commandLineField bind:@"value" toObject:self.representedObject withKeyPath:@"command" options:@{}];
}

- (void)updateContent {
    CustomCommandAction *action = self.representedObject;
    NSString *command = action.command;

    [self.checkbox setTitle:(command.length > 0 ? [NSString stringWithFormat:NSLocalizedString(@"Run %@", nil), command] : NSLocalizedString(@"Run custom command", nil))];
}

+ (NSArray *)representedObjectKeyPathsToObserve {
    return @[@"command"];
}

@end
