
#import "ActionListView.h"
#import "ActionList.h"
#import "LiveReload-Swift-x.h"
#import "GroupHeaderRow.h"
#import "Project.h"

#import "ActionsGroupHeaderRow.h"
#import "RunCustomCommandActionRow.h"
#import "RunScriptActionRow.h"
#import "AddActionRow.h"

#import "FiltersGroupHeaderRow.h"
#import "AddFilterRow.h"
#import "FilterActionRow.h"

#import "AddCompilationActionRow.h"


static void *ActionListView_Action_Context = "ActionListView_Action_Context";


@interface ActionListView () <BaseActionRowDelegate>

@end


@implementation ActionListView {
    BOOL _loaded;
    NSDictionary *_metrics;

    FiltersGroupHeaderRow *_compilersHeaderRow;
    AddCompilationActionRow *_compilersAddRow;

    ActionsGroupHeaderRow *_actionsHeaderRow;
    AddActionRow *_actionsAddRow;

    FiltersGroupHeaderRow *_filtersHeaderRow;
    AddFilterRow *_filtersAddRow;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat overhang = 5.0;
        _metrics = @{@"indentL1": @(overhang), @"indentL2": @(overhang), @"indentL3": @(overhang+18), @"checkboxToControl": @1.0, @"buttonBarGapMin": @20.0, @"buttonGap": @1.0, @"columnGapMin": @8.0, @"actionWidthMax": @180.0,
             @"columnHeaderStyle": @{NSFontAttributeName: [NSFont systemFontOfSize:11], NSForegroundColorAttributeName: [NSColor headerColor]},
        };
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
    if (context == ActionListView_Action_Context) {
        [self updateCompilerRows];
        [self updateFilterRows];
        [self updateActionRows];
    } else
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

- (void)updateCompilerRows {
    [self updateRowsOfClass:[BaseActionRow class] betweenRow:_compilersHeaderRow andRow:_compilersAddRow newRepresentedObjects:self.actionList.compilerActions create:^ATStackViewRow *(Action *action) {
        Class rowClass = action.type.rowClass;
        if (rowClass) {
            return [rowClass rowWithRepresentedObject:action metrics:_metrics userInfo:@{@"project": self.project} delegate:self];
        } else {
            return nil;
        }
    }];
}

- (void)updateFilterRows {
    [self updateRowsOfClass:[BaseActionRow class] betweenRow:_filtersHeaderRow andRow:_filtersAddRow newRepresentedObjects:self.actionList.filterActions create:^ATStackViewRow *(Action *action) {
        Class rowClass = action.type.rowClass;
        if (rowClass) {
            return [rowClass rowWithRepresentedObject:action metrics:_metrics userInfo:@{@"project": self.project} delegate:self];
        } else {
            return nil;
        }
    }];
}

- (void)updateActionRows {
    [self updateRowsOfClass:[BaseActionRow class] betweenRow:_actionsHeaderRow andRow:_actionsAddRow newRepresentedObjects:self.actionList.postprocActions create:^ATStackViewRow *(Action *action) {
        Class rowClass = action.type.rowClass;
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

    _compilersHeaderRow = [FiltersGroupHeaderRow rowWithRepresentedObject:@{@"title": @"Compilers"} metrics:_metrics userInfo:nil delegate:self];
    _compilersAddRow = [AddCompilationActionRow rowWithRepresentedObject:self.actionList metrics:_metrics userInfo:nil delegate:self];
    [self addItem:_compilersHeaderRow];
    [self addItem:_compilersAddRow];

    _filtersHeaderRow = [FiltersGroupHeaderRow rowWithRepresentedObject:@{@"title": @"Filters"} metrics:_metrics userInfo:nil delegate:self];
    _filtersAddRow = [AddFilterRow rowWithRepresentedObject:self.actionList metrics:_metrics userInfo:nil delegate:self];
    [self addItem:_filtersHeaderRow];
    [self addItem:_filtersAddRow];

    _actionsHeaderRow = [ActionsGroupHeaderRow rowWithRepresentedObject:@{@"title": @"Other actions"} metrics:_metrics userInfo:nil delegate:self];
    _actionsAddRow = [AddActionRow rowWithRepresentedObject:self.actionList metrics:_metrics userInfo:nil delegate:self];
    [self addItem:_actionsHeaderRow];
    [self addItem:_actionsAddRow];

    [self updateCompilerRows];
    [self updateFilterRows];
    [self updateActionRows];
}

- (void)removeActionClicked:(id)action {
    NSInteger index = [self.actionList.actions indexOfObject:action];
    if (index != NSNotFound)
        [self.actionList removeObjectFromActionsAtIndex:index];
}

@end
