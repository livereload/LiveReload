@import LRActionKit;

#import "RulebookView.h"
#import "LiveReload-Swift-x.h"
#import "GroupHeaderRow.h"
#import "Project.h"

#import "ActionsGroupHeaderRow.h"
#import "CustomCommandRuleRow.h"
#import "UserScriptRuleRow.h"
#import "AddActionRow.h"

#import "FiltersGroupHeaderRow.h"
#import "AddFilterRow.h"
#import "FilterRuleRow.h"

#import "AddCompilationActionRow.h"


@interface RulebookView () <BaseActionRowDelegate>

@end


@implementation RulebookView {
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setRulebook:(Rulebook *)rulebook {
    if (_rulebook != rulebook) {
        if (_rulebook) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:[Rulebook didChangeNotification] object:_rulebook];
        }
        _rulebook = rulebook;
        if (_rulebook) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rulebookDidChange:) name:[Rulebook didChangeNotification] object:_rulebook];
        }
        _loaded = NO;
        [self setNeedsUpdateConstraints:YES];
    }
}

- (void)setProject:(Project *)project {
    if (_project != project) {
        _project = project;
        self.rulebook = project.rulebook;

        _loaded = NO;
        [self setNeedsUpdateConstraints:YES];
    }
}

- (void)rulebookDidChange:(NSNotification *)notification {
    [self updateCompilerRows];
    [self updateFilterRows];
    [self updateActionRows];
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
    [self updateRowsOfClass:[BaseRuleRow class] betweenRow:_compilersHeaderRow andRow:_compilersAddRow newRepresentedObjects:self.rulebook.compilationRules create:^ATStackViewRow *(Rule *rule) {
        Class rowClass = NSClassFromString(rule.action.rowClassName);
        if (rowClass) {
            return [rowClass rowWithRepresentedObject:rule metrics:_metrics userInfo:@{@"project": self.project} delegate:self];
        } else {
            return nil;
        }
    }];
}

- (void)updateFilterRows {
    [self updateRowsOfClass:[BaseRuleRow class] betweenRow:_filtersHeaderRow andRow:_filtersAddRow newRepresentedObjects:self.rulebook.filterRules create:^ATStackViewRow *(Rule *rule) {
        Class rowClass = NSClassFromString(rule.action.rowClassName);
        if (rowClass) {
            return [rowClass rowWithRepresentedObject:rule metrics:_metrics userInfo:@{@"project": self.project} delegate:self];
        } else {
            return nil;
        }
    }];
}

- (void)updateActionRows {
    [self updateRowsOfClass:[BaseRuleRow class] betweenRow:_actionsHeaderRow andRow:_actionsAddRow newRepresentedObjects:self.rulebook.postprocRules create:^ATStackViewRow *(Rule *rule) {
        Class rowClass = NSClassFromString(rule.action.rowClassName);
        if (rowClass) {
            return [rowClass rowWithRepresentedObject:rule metrics:_metrics userInfo:@{@"project": self.project} delegate:self];
        } else {
            return nil;
        }
    }];
}

- (void)loadRows {
#if 0
    [self addItem:[[CompilersCategoryRow alloc] initWithTitle:@"Compilers:"]];
    for (Rule *rule in self.rulebook.rules) {
        [self addItem:[self actionRowViewForAction:rule]];
    }
    [self addItem:[self addButtonRowWithPrompt:@"Add compiler" choices:@[@"SASS", @"Compass", @"LESS"]]];
#endif

    _compilersHeaderRow = [FiltersGroupHeaderRow rowWithRepresentedObject:@{@"title": @"Compilers"} metrics:_metrics userInfo:nil delegate:self];
    _compilersAddRow = [AddCompilationActionRow rowWithRepresentedObject:self.rulebook metrics:_metrics userInfo:nil delegate:self];
    [self addItem:_compilersHeaderRow];
    [self addItem:_compilersAddRow];

    _filtersHeaderRow = [FiltersGroupHeaderRow rowWithRepresentedObject:@{@"title": @"Filters"} metrics:_metrics userInfo:nil delegate:self];
    _filtersAddRow = [AddFilterRow rowWithRepresentedObject:self.rulebook metrics:_metrics userInfo:nil delegate:self];
    [self addItem:_filtersHeaderRow];
    [self addItem:_filtersAddRow];

    _actionsHeaderRow = [ActionsGroupHeaderRow rowWithRepresentedObject:@{@"title": @"Other rules"} metrics:_metrics userInfo:nil delegate:self];
    _actionsAddRow = [AddActionRow rowWithRepresentedObject:self.rulebook metrics:_metrics userInfo:nil delegate:self];
    [self addItem:_actionsHeaderRow];
    [self addItem:_actionsAddRow];

    [self updateCompilerRows];
    [self updateFilterRows];
    [self updateActionRows];
}

- (void)removeActionClicked:(id)rule {
    NSInteger index = [self.rulebook.rules indexOfObject:rule];
    if (index != NSNotFound)
        [self.rulebook removeObjectFromRulesAtIndex:index];
}

@end
