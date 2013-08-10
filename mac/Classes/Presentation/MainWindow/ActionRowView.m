
#import "ActionRowView.h"
#import "ActionType.h"
#import "ActionList.h"
#import "Project.h"


@interface ActionRowView ()

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
        _commandPopUp = [[NSPopUpButton alloc] initWithFrame:CGRectZero pullsDown:NO];
        _commandPopUp.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_commandPopUp];

        _whenLabel = [[NSTextField alloc] init];
        _whenLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_whenLabel setEditable:NO];
        [_whenLabel setBordered:NO];
        _whenLabel.stringValue = @"when";
        [self addSubview:_whenLabel];

        _filterPopUp = [[NSPopUpButton alloc] initWithFrame:CGRectZero pullsDown:NO];
        _filterPopUp.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_filterPopUp];

        _isChangedLabel = [[NSTextField alloc] init];
        _isChangedLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_isChangedLabel setEditable:NO];
        [_isChangedLabel setBordered:NO];
        _isChangedLabel.stringValue = @"is changed.";
        [self addSubview:_isChangedLabel];

        _optionsButton = [[NSButton alloc] init];
        _optionsButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_optionsButton setBezelStyle:NSRoundRectBezelStyle];
        [_optionsButton setTitle:@"Options"];
        [self addSubview:_optionsButton];

        _addButton = [[NSButton alloc] init];
        _addButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_addButton setBezelStyle:NSRoundRectBezelStyle];
        [_addButton setImage:[NSImage imageNamed:@"NSAddTemplate"]];
        _addButton.target = self;
        _addButton.action = @selector(addClicked:);
        [self addSubview:_addButton];

        _removeButton = [[NSButton alloc] init];
        _removeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_removeButton setBezelStyle:NSRoundRectBezelStyle];
        [_removeButton setImage:[NSImage imageNamed:@"NSRemoveTemplate"]];
        _removeButton.target = self;
        _removeButton.action = @selector(removeClicked:);
        [self addSubview:_removeButton];

        NSDictionary *bindings = @{ @"commandPopUp": _commandPopUp, @"whenLabel": _whenLabel, @"filterPopUp": _filterPopUp, @"isChangedLabel": _isChangedLabel, @"optionsButton": _optionsButton, @"removeButton": _removeButton, @"addButton": _addButton };

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(0)-[commandPopUp(>=100,==filterPopUp)]-[whenLabel]-[filterPopUp]-[isChangedLabel]-(20@200,>=20)-[optionsButton]-[removeButton]-(4)-[addButton]-(0)-|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:bindings]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_commandPopUp attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[commandPopUp]-(>=0)-|" options:0 metrics:nil views:bindings]];    }
    return self;
}

- (void)setProject:(Project *)project {
    if (_project != project) {
        _project = project;
        _actionList = project.actionList;
    }
}

- (void)awakeFromNib {
    NSLog(@"self.constraints = %@", self.constraints);
    [self removeConstraints:self.constraints];

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
