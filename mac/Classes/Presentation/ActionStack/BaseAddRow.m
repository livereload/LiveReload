
#import "BaseAddRow.h"
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

    [self.menuPullDown makeWidthEqualTo:150];

    [self addConstraintsWithVisualFormat:@"|-indentL2-[menuPullDown(>=120)]"];
    [self addFullHeightConstraintsForSubview:self.menuPullDown];

//    [self alignView:self.menuPullDown toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.menuPullDown toColumnNamed:@"add"];
}

@end
