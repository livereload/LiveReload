
#import "AddFilterRow.h"

@implementation AddFilterRow

- (void)loadContent {
    [super loadContent];
    [self updateMenu];
}

- (void)updateMenu {
    [super updateMenu];

    NSMenuItem *item = [self.menu addItemWithTitle:@"autoprefixer" action:@selector(addActionClicked:) keyEquivalent:@""];
    item.representedObject = @{@"action": @"autoprefixer"};
    item.target = self;
}

@end
