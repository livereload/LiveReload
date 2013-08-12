
#import "RunCustomCommandActionRow.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"


@interface RunCustomCommandActionRow ()

//@property(nonatomic, strong) NSTextField *runLabel;
//@property(nonatomic, strong) NSTextField *commandField;
@property(nonatomic, strong) NSPopUpButton *filterPopUp;

@end


@implementation RunCustomCommandActionRow

- (void)loadContent {
    [super loadContent];

    [self.checkbox setTitle:@"Run custom command"];

//    self.runLabel = [[NSTextField staticLabelWithString:@"Run"] addedToView:self];
//    _commandField = [[NSTextField editableField] addedToView:self];
    self.filterPopUp = [[[NSPopUpButton popUpButton] withBezelStyle:NSRoundRectBezelStyle] addedToView:self];

    [self addConstraintsWithVisualFormat:@"|-indentL2-[checkbox]-[filterPopUp(>=120)]-(>=buttonBarGapMin)-[optionsButton]-buttonGap-[removeButton]|" options:NSLayoutFormatAlignAllCenterY];
    [self addFullHeightConstraintsForSubview:self.filterPopUp];

    [self alignView:self.checkbox toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.filterPopUp toColumnNamed:@"filter"];
}

@end
