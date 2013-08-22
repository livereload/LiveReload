
#import "ActionListView.h"
#import "ActionList.h"
#import "Action.h"
#import "GroupHeaderRow.h"
#import "Project.h"

#import "ActionsGroupHeaderRow.h"
#import "RunCustomCommandActionRow.h"
#import "RunScriptActionRow.h"
#import "AddActionRow.h"

#import "FiltersGroupHeaderRow.h"
#import "AddFilterRow.h"


static void *ActionListView_Action_Context = "ActionListView_Action_Context";


@interface ActionListView () <BaseActionRowDelegate>

@end


@implementation ActionListView {
    BOOL _loaded;
    NSDictionary *_metrics;

    NSDictionary *_rowClassByActionName;

    ActionsGroupHeaderRow *_actionsHeaderRow;
    AddActionRow *_actionsAddRow;

    FiltersGroupHeaderRow *_filtersHeaderRow;
    AddFilterRow *_filtersAddRow;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _metrics = @{@"indentL2": @18.0, @"indentL3": @36.0, @"checkboxToControl": @1.0, @"buttonBarGapMin": @20.0, @"buttonGap": @1.0, @"columnGapMin": @8.0, @"actionWidthMax": @180.0,
             @"columnHeaderStyle": @{NSFontAttributeName: [NSFont systemFontOfSize:11], NSForegroundColorAttributeName: [NSColor headerColor]},
        };
        _rowClassByActionName = @{@"command": [RunCustomCommandActionRow class], @"script": [RunScriptActionRow class]};
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

- (void)setProject:(Project *)project {
    if (_project != project) {
        _project = project;
        self.actionList = project.actionList;

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

- (void)updateFilterRows {
    [self updateRowsOfClass:[BaseActionRow class] betweenRow:_filtersHeaderRow andRow:_filtersAddRow newRepresentedObjects:self.actionList.actions create:^ATStackViewRow *(Action *action) {
        Class rowClass = _rowClassByActionName[action.typeIdentifier];
        if (rowClass) {
            return [rowClass rowWithRepresentedObject:action metrics:_metrics userInfo:@{@"project": self.project} delegate:self];
        } else {
            return nil;
        }
    }];
}

- (void)updateActionRows {
    [self updateRowsOfClass:[BaseActionRow class] betweenRow:_actionsHeaderRow andRow:_actionsAddRow newRepresentedObjects:self.actionList.actions create:^ATStackViewRow *(Action *action) {
        Class rowClass = _rowClassByActionName[action.typeIdentifier];
        if (rowClass) {
            return [rowClass rowWithRepresentedObject:action metrics:_metrics userInfo:@{@"project": self.project} delegate:self];
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
#endif

    _filtersHeaderRow = [FiltersGroupHeaderRow rowWithRepresentedObject:@{@"title": @"Filters:"} metrics:_metrics userInfo:nil delegate:self];
    _filtersAddRow = [AddFilterRow rowWithRepresentedObject:self.actionList metrics:_metrics userInfo:nil delegate:self];
    [self addItem:_filtersHeaderRow];
    [self addItem:_filtersAddRow];

    _actionsHeaderRow = [ActionsGroupHeaderRow rowWithRepresentedObject:@{@"title": @"Other actions:"} metrics:_metrics userInfo:nil delegate:self];
    _actionsAddRow = [AddActionRow rowWithRepresentedObject:self.actionList metrics:_metrics userInfo:nil delegate:self];
    [self addItem:_actionsHeaderRow];
    [self addItem:_actionsAddRow];

    [self updateFilterRows];
    [self updateActionRows];
}

- (void)removeActionClicked:(id)action {
    NSInteger index = [self.actionList.actions indexOfObject:action];
    if (index != NSNotFound)
        [self.actionList removeObjectFromActionsAtIndex:index];
}

@end
