
#import "AddActionRow.h"
#import "ActionList.h"

@implementation AddActionRow

- (void)loadContent {
    [super loadContent];
    [self updateMenu];
}

- (void)updateMenu {
    NSMenu *menu = self.menuPullDown.menu;

    [menu removeAllItems];
    [menu addItemWithTitle:@"Add action" action:NULL keyEquivalent:@""];

    NSMenuItem *item = [menu addItemWithTitle:@"Run custom command" action:@selector(addItemClicked:) keyEquivalent:@""];
    item.representedObject = @{@"action": @"command"};
    item.target = self;
}

- (void)addItemClicked:(NSMenuItem *)sender {
    NSDictionary *prototype = sender.representedObject;
    if (prototype) {
        ActionList *actionList = self.representedObject;
        [actionList addActionWithPrototype:prototype];
    }
}

@end
