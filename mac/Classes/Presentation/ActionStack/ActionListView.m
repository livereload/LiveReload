
#import "ActionListView.h"
#import "ActionList.h"
#import "Action.h"
#import "GroupHeaderRow.h"
#import "ActionRowView.h"
#import "ActionsGroupHeaderRow.h"
#import "RunCustomCommandActionRow.h"
#import "AddActionRow.h"


static void *ActionListView_Action_Context = "ActionListView_Action_Context";


@interface ActionListView () <ActionRowViewDelegate>

@end


@implementation ActionListView {
    BOOL _loaded;
    NSDictionary *_metrics;

    NSDictionary *_rowClassByActionName;

    ActionsGroupHeaderRow *_actionsHeaderRow;
    AddActionRow *_actionsAddRow;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _metrics = @{@"indentL2": @18.0, @"indentL3": @36.0, @"checkboxToControl": @1.0, @"buttonBarGapMin": @20.0, @"buttonGap": @1.0, @"columnGapMin": @8.0};
        _rowClassByActionName = @{@"command": [RunCustomCommandActionRow class]};
    }
    return self;
}

- (void)setActionList:(ActionList *)actionList {
    if (_actionList != actionList) {
        [_actionList removeObserver:self forKeyPath:@"actions" context:ActionListView_Action_Context];
        _actionList = actionList;
        [_actionList addObserver:self forKeyPath:@"actions" options:0 context:ActionListView_Action_Context];
        _loaded = NO;
        [self setNeedsUpdateConstraints:YES];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == ActionListView_Action_Context)
        [self updateActionRows];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)updateConstraints {
    if (!_loaded) {
        _loaded = YES;
        [self removeAllItems];
        [self loadRows];
    }

    [super updateConstraints];
}

- (void)updateActionRows {
    [self updateRowsOfClass:[BaseActionRow class] betweenRow:_actionsHeaderRow andRow:_actionsAddRow newRepresentedObjects:self.actionList.actions create:^ATStackViewRow *(Action *action) {
        Class rowClass = _rowClassByActionName[action.typeIdentifier];
        if (rowClass) {
            return [rowClass rowWithRepresentedObject:action metrics:_metrics delegate:self];
        } else {
            return nil;
        }
    }];
}

- (void)loadRows {
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

    _actionsHeaderRow = [ActionsGroupHeaderRow rowWithRepresentedObject:@{@"title": @"Other actions:"} metrics:_metrics delegate:self];
    _actionsAddRow = [AddActionRow rowWithRepresentedObject:self.actionList metrics:_metrics delegate:self];
    [self addItem:_actionsHeaderRow];
    [self addItem:_actionsAddRow];

    [self updateActionRows];

//    for (Action *action in self.actionList.actions) {
////        [self addItem:[self actionRowViewForAction:action]];
//        Class rowClass = rowClassByActionName[action.typeIdentifier];
//        if (rowClass) {
//            [self addItem:[rowClass rowWithRepresentedObject:action metrics:_metrics delegate:self]];
//        }
//    }
        
}

- (BaseAddRow *)addButtonRowWithPrompt:(NSString *)prompt choices:(NSArray *)choices {
    BaseAddRow *row = [BaseAddRow new];
    row.metrics = _metrics;
    [row.menuPullDown addItemWithTitle:prompt];
    [row.menuPullDown addItemsWithTitles:choices];
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
