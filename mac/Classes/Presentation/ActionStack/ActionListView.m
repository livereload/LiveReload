
#import "ActionListView.h"
#import "ActionList.h"
#import "Action.h"
#import "GroupHeaderRow.h"
#import "ActionRowView.h"
#import "AddActionRow.h"
#import "ActionsGroupHeaderRow.h"
#import "RunCustomCommandActionRow.h"


@interface ActionListView () <ActionRowViewDelegate>

@end


@implementation ActionListView {
    BOOL _loaded;
    NSDictionary *_metrics;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _metrics = @{@"indentL2": @18.0, @"indentL3": @36.0, @"checkboxToControl": @1.0, @"buttonBarGapMin": @20.0, @"buttonGap": @1.0, @"columnGapMin": @8.0};
    }
    return self;
}

- (void)setActionList:(ActionList *)actionList {
    if (_actionList != actionList) {
        _actionList = actionList;
        [self setNeedsUpdateConstraints:YES];
    }
}

- (void)updateConstraints {
    if (!_loaded) {
        _loaded = YES;
        [self removeAllItems];
        [self loadRows];
    }

    [super updateConstraints];
}

- (void)loadRows {
    NSDictionary *rowClassByActionName = @{@"command": [RunCustomCommandActionRow class]};
#if 0
    [self addItem:[[CompilersCategoryRow alloc] initWithTitle:@"Compilers:"]];
    for (Action *action in self.actionList.actions) {
        [self addItem:[self actionRowViewForAction:action]];
    }
    [self addItem:[self addButtonRowWithPrompt:@"Add compiler" choices:@[@"SASS", @"Compass", @"LESS"]]];

    [self addItem:[[FiltersCategoryRow alloc] initWithTitle:@"Filters:"]];
    for (Action *action in self.actionList.actions) {
        [self addItem:[self actionRowViewForAction:action]];
    }
    [self addItem:[self addButtonRowWithPrompt:@"Add filter" choices:@[@"autoprefix"]]];
#endif

    [self addItem:[ActionsGroupHeaderRow rowWithRepresentedObject:@{@"title": @"Other actions:"} metrics:_metrics delegate:self]];
    for (Action *action in self.actionList.actions) {
//        [self addItem:[self actionRowViewForAction:action]];
        Class rowClass = rowClassByActionName[action.typeIdentifier];
        if (rowClass) {
            [self addItem:[rowClass rowWithRepresentedObject:action metrics:_metrics delegate:self]];
        }
    }
    [self addItem:[self addButtonRowWithPrompt:@"Add action" choices:@[@"Run custom command", @"Run foo.sh", @"Run bar.sh"]]];
        
}

- (Class)actionRowClassForAction:(Action *)action {
}

- (AddActionRow *)addButtonRowWithPrompt:(NSString *)prompt choices:(NSArray *)choices {
    AddActionRow *row = [AddActionRow new];
    row.metrics = _metrics;
    [row.actionPullDown addItemWithTitle:prompt];
    [row.actionPullDown addItemsWithTitles:choices];
    return row;
}

- (void)didInvokeAddInActionRowView:(ActionRowView *)rowView {
    NSInteger index = [self.actionList.actions indexOfObject:rowView.representedObject];
    if (index != NSNotFound) {
        Action *action = [CustomCommandAction new];
        [self.actionList insertObject:action inActionsAtIndex:index + 1];
        [self setNeedsUpdateConstraints:YES];
    }
}

- (void)didInvokeRemoveInActionRowView:(ActionRowView *)rowView {
    NSInteger index = [self.actionList.actions indexOfObject:rowView.representedObject];
    if (index != NSNotFound) {
        [self.actionList removeObjectFromActionsAtIndex:index];
        [self setNeedsUpdateConstraints:YES];
    }
}

@end
