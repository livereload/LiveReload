
#import "AddCompilationActionRow.h"
#import "ActionList.h"
#import "PluginManager.h"
#import "ATFunctionalStyle.h"

@implementation AddCompilationActionRow

- (void)loadContent {
    [super loadContent];
    [self updateMenu];
}

- (void)updateMenu {
    NSMenu *menu = self.menuPullDown.menu;

    [menu removeAllItems];
    [menu addItemWithTitle:@"Add compiler" action:NULL keyEquivalent:@""];

    NSArray *compilerTypes = [[PluginManager sharedPluginManager].actionTypes filteredArrayUsingBlock:^BOOL(ActionType *actionType) {
        return actionType.kind == ActionKindCompiler;
    }];

    for (ActionType *actionType in compilerTypes) {
        NSMenuItem *item = [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@", nil), actionType.name] action:@selector(addActionClicked:) keyEquivalent:@""];
        item.representedObject = @{@"action": actionType.identifier};
        item.target = self;
    }
}

@end
