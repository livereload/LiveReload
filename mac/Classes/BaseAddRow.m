
#import "BaseAddRow.h"
#import "ActionList.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"


@interface BaseAddRow ()
@end


@implementation BaseAddRow

- (NSPopUpButton *)menuPullDown {
    if (!_menuPullDown) {
        _menuPullDown = [[[NSPopUpButton pullDownButton] withBezelStyle:NSRoundRectBezelStyle] addedToView:self];
        _menuPullDown.font = [NSFont systemFontOfSize:12.0];
    }
    return _menuPullDown;
}

- (void)loadContent {
    [super loadContent];
    [self updateMenu];

    [self.menuPullDown makeWidthEqualTo:32];

    [self addConstraintsWithVisualFormat:@"|-indentL2-[menuPullDown]"];
    [self addFullHeightConstraintsForSubview:self.menuPullDown];

//    [self alignView:self.menuPullDown toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.menuPullDown toColumnNamed:@"add" alignment:ATStackViewColumnAlignmentLeading];
}

- (IBAction)addActionClicked:(NSMenuItem *)sender {
    NSDictionary *prototype = sender.representedObject;
    if (prototype) {
        ActionList *actionList = self.representedObject;
        [actionList addActionWithPrototype:prototype];
    }
}

- (NSMenu *)menu {
    return self.menuPullDown.menu;
}

- (void)updateMenu {
    [self.menu removeAllItems];

    NSMenuItem *first = [self.menu addItemWithTitle:@"" action:NULL keyEquivalent:@""];
    first.image = [NSImage imageNamed:@"NSAddTemplate"];
}

@end
