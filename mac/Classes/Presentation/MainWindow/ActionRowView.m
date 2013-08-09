
#import "ActionRowView.h"
#import "ActionType.h"
#import "ActionList.h"
#import "Project.h"


@interface ActionRowView ()

@property (weak) IBOutlet NSPopUpButton *commandPopUp;
@property (weak) IBOutlet NSPopUpButton *filterPopUp;
@property (weak) IBOutlet NSButton *optionsButton;
@property (weak) IBOutlet NSButton *removeButton;
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSTextField *whenLabel;
@property (weak) IBOutlet NSTextField *isChangedLabel;

@end


@implementation ActionRowView {
    ActionList *_actionList;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)setProject:(Project *)project {
    if (_project != project) {
        _project = project;
        _actionList = project.actionList;
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self removeConstraints:self.constraints];

    NSDictionary *bindings = @{ @"commandPopUp": _commandPopUp, @"whenLabel": _whenLabel, @"filterPopUp": _filterPopUp, @"isChangedLabel": _isChangedLabel, @"optionsButton": _optionsButton, @"removeButton": _removeButton, @"addButton": _addButton };
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[commandPopUp(>=100,==filterPopUp)]-[whenLabel]-[filterPopUp]-[isChangedLabel]-(20@200,>=20)-[optionsButton]-[removeButton]-(4)-[addButton]-(0)-|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:bindings]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_commandPopUp attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[commandPopUp]-(>=0)-|" options:0 metrics:nil views:bindings]];
}

- (IBAction)addClicked:(id)sender {
    [_delegate didInvokeAddInActionRowView:self];
}

- (IBAction)removeClicked:(id)sender {
    [_delegate didInvokeRemoveInActionRowView:self];
}

- (IBAction)optionsClicked:(id)sender {
}

//- (void)drawRect:(NSRect)dirtyRect {
//    [[NSColor yellowColor] set];
//    NSRectFill(self.bounds);
//}

@end
