
#import "ActionListView.h"
#import "ActionList.h"
#import "Action.h"
#import "GroupHeaderRow.h"
#import "ActionsGroupHeaderRow.h"
#import "RunCustomCommandActionRow.h"
#import "AddActionRow.h"


static void *ActionListView_Action_Context = "ActionListView_Action_Context";


@interface ActionListView () <BaseActionRowDelegate>

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
        _metrics = @{@"indentL2": @18.0, @"indentL3": @36.0, @"checkboxToControl": @1.0, @"buttonBarGapMin": @20.0, @"buttonGap": @1.0, @"columnGapMin": @8.0, @"actionWidthMax": @180.0};
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
}

- (void)removeActionClicked:(id)action {
    NSInteger index = [self.actionList.actions indexOfObject:action];
    if (index != NSNotFound)
        [self.actionList removeObjectFromActionsAtIndex:index];
}

@end
