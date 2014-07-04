
#import "AddCompilationActionRow.h"
#import "Rulebook.h"
#import "LiveReload-Swift-x.h"
#import "ATFunctionalStyle.h"

@implementation AddCompilationActionRow

- (void)loadContent {
    [super loadContent];
    [self updateMenu];
}

- (void)updateMenu {
    [super updateMenu];

    NSArray *compilerTypes = [[PluginManager sharedPluginManager].actions filteredArrayUsingBlock:^BOOL(Action *action) {
        return action.kind == ActionKindCompiler;
    }];

    for (Action *action in compilerTypes) {
        NSMenuItem *item = [self.menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@", nil), action.name] action:@selector(addActionClicked:) keyEquivalent:@""];
        item.representedObject = @{@"action": action.identifier};
        item.target = self;
    }

    // TODO: remove special treatment of Compass
    {
        NSMenuItem *item = [self.menu addItemWithTitle:@"Compass" action:@selector(addActionClicked:) keyEquivalent:@""];
        item.representedObject = @{@"action": @"compass"};
        item.target = self;
    }
}

@end
