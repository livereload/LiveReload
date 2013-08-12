
#import "AddActionRow.h"
#import "ATMacViewCreation.h"


@interface AddActionRow ()
@end


@implementation AddActionRow

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _actionPullDown = [[[NSPopUpButton pullDownButton] withBezelStyle:NSRoundRectBezelStyle] addedToView:self];
        _actionPullDown.font = [NSFont systemFontOfSize:12.0];
    }
    return self;
}

- (void)updateConstraints {
    [super updateConstraints];
    [self removeConstraints:self.constraints];

    NSDictionary *bindings = @{@"actionPullDown": _actionPullDown};
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-indentL3-[actionPullDown(120)]" options:0 metrics:self.metrics views:bindings]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[actionPullDown]|" options:0 metrics:self.metrics views:bindings]];
}


@end
