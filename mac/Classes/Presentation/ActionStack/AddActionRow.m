
#import "AddActionRow.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"


@interface AddActionRow ()
@end


@implementation AddActionRow

- (NSPopUpButton *)actionPullDown {
    if (!_actionPullDown) {
        _actionPullDown = [[[NSPopUpButton pullDownButton] withBezelStyle:NSRoundRectBezelStyle] addedToView:self];
        _actionPullDown.font = [NSFont systemFontOfSize:12.0];
    }
    return _actionPullDown;
}

- (void)loadContent {
    [super loadContent];

    [self addConstraintsWithVisualFormat:@"|-indentL3-[actionPullDown(>=120)]"];
    [self addFullHeightConstraintsForSubview:self.actionPullDown];

    [self alignView:self.actionPullDown toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
}


@end
