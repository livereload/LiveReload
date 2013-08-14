
#import "AddFilterRow.h"

@implementation AddFilterRow

- (void)loadContent {
    [super loadContent];
    [self updateMenu];
}

- (void)updateMenu {
    NSMenu *menu = self.menuPullDown.menu;

    [menu removeAllItems];
    [menu addItemWithTitle:@"Add filter" action:NULL keyEquivalent:@""];

    NSMenuItem *item = [menu addItemWithTitle:@"autoprefixer" action:@selector(addActionClicked:) keyEquivalent:@""];
    item.representedObject = @{@"action": @"autoprefixer"};
    item.target = self;
}

@end
