
#import "ActionRowView.h"
#import "ActionType.h"
#import "ActionList.h"
#import "Project.h"
#import "ATMacViewCreation.h"


@interface ActionRowView ()

@property (nonatomic, strong) IBOutlet NSButton *checkbox;
@property (nonatomic, strong) IBOutlet NSPopUpButton *commandPopUp;
@property (nonatomic, strong) IBOutlet NSPopUpButton *filterPopUp;
@property (nonatomic, strong) IBOutlet NSButton *optionsButton;
@property (nonatomic, strong) IBOutlet NSButton *removeButton;
@property (nonatomic, strong) IBOutlet NSButton *addButton;
@property (nonatomic, strong) IBOutlet NSTextField *whenLabel;
@property (nonatomic, strong) IBOutlet NSTextField *isChangedLabel;

@end


@implementation ActionRowView {
    ActionList *_actionList;
    NSMutableArray *_actionItems;
}

- (id)init {
    self = [super init];
    if (self) {
        _checkbox = [[NSButton buttonWithTitle:@"" type:NSSwitchButton bezelStyle:NSRoundRectBezelStyle] addedToView:self];

        _commandPopUp = [[[NSPopUpButton popUpButton] withBezelStyle:NSRoundRectBezelStyle] addedToView:self];

        _whenLabel = [[NSTextField staticLabelWithString:@"when"] addedToView:self];

        _filterPopUp = [[[NSPopUpButton popUpButton] withBezelStyle:NSRoundRectBezelStyle] addedToView:self];

        _isChangedLabel = [[NSTextField staticLabelWithString:@"is changed."] addedToView:self];

        _optionsButton = [[[NSButton buttonWithImageNamed:@"LROptionsTemplate" type:NSPushOnPushOffButton bezelStyle:NSRecessedBezelStyle] withTarget:self action:@selector(optionsClicked:)] addedToView:self];

        _removeButton = [[[NSButton buttonWithImageNamed:@"NSRemoveTemplate" type:NSPushOnPushOffButton bezelStyle:NSRecessedBezelStyle] withTarget:self action:@selector(removeClicked:)] addedToView:self];
    }
    return self;
}

- (void)awakeFromNib {
    NSLog(@"self.constraints = %@", self.constraints);
    [self removeConstraints:self.constraints];

}

- (void)updateConstraints {
    [super updateConstraints];

    [self removeConstraints:self.constraints];

    NSDictionary *bindings = @{ @"checkbox": _checkbox, @"commandPopUp": _commandPopUp, @"whenLabel": _whenLabel, @"filterPopUp": _filterPopUp, @"isChangedLabel": _isChangedLabel, @"optionsButton": _optionsButton, @"removeButton": _removeButton };

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-indentL2-[checkbox]-1-[commandPopUp(>=100,==filterPopUp)]-[whenLabel]-[filterPopUp]-[isChangedLabel]-(20@200,>=20)-[optionsButton]-1-[removeButton]|" options:NSLayoutFormatAlignAllCenterY metrics:self.metrics views:bindings]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_commandPopUp attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[commandPopUp]-(>=0)-|" options:0 metrics:self.metrics views:bindings]];
}

- (void)renderActionList {
    [_actionItems removeAllObjects];
    [_commandPopUp removeAllItems];

    [self addItemWithData:@{@"action": @"command", @"title": @"Run custom command"}];
    [self addSeparatorItem];
    for (NSDictionary *itemInfo in _actionItems) {
    }
}

- (void)addItemWithData:(NSDictionary *)data {
    [_actionItems addObject:data];
    [_commandPopUp insertItemWithTitle:data[@"title"] atIndex:_actionItems.count];
}

- (void)addSeparatorItem {
    [_actionItems addObject:@{@"title": @"-"}];
    [_commandPopUp.menu addItem:[NSMenuItem separatorItem]];
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
