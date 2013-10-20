
#import "ATMacViewCreation.h"

@implementation NSTextField (ATMacViewCreation)

+ (NSTextField *)staticLabelWithString:(NSString *)text style:(NSDictionary *)style {
    return [[self staticLabelWithString:text] withStyle:style];
}

+ (NSTextField *)staticLabelWithString:(NSString *)text {
    NSTextField *view = [[self alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setBordered:NO];
    [view setEditable:NO];
    [view setDrawsBackground:NO];
    [view setStringValue:text];
    return view;
}

+ (NSTextField *)staticLabelWithAttributedString:(NSAttributedString *)text {
    NSTextField *view = [[self alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setBordered:NO];
    [view setEditable:NO];
    [view setAttributedStringValue:text];
    return view;
}

+ (NSTextField *)editableField {
    NSTextField *view = [[self alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

- (instancetype)withStyle:(NSDictionary *)style {
    NSFont *font = style[NSFontAttributeName];
    if (font)
        self.font = font;
    NSColor *textColor = style[NSForegroundColorAttributeName];
    if (textColor)
        self.textColor = textColor;
    return self;
}

@end


@implementation NSTextView (ATMacViewCreation)

+ (NSTextView *)editableTextView {
    NSTextView *view = [[self alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

@end


@implementation NSPopUpButton (ATMacViewCreation)

+ (instancetype)popUpButton {
    NSPopUpButton *view = [[self alloc] initWithFrame:CGRectZero pullsDown:NO];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

+ (instancetype)pullDownButton {
    NSPopUpButton *view = [[self alloc] initWithFrame:CGRectZero pullsDown:YES];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

@end


@implementation NSButton (ATMacViewCreation)

+ (NSButton *)buttonWithTitle:(NSString *)title type:(NSButtonType)type bezelStyle:(NSBezelStyle)bezelStyle {
    NSButton *view = [[self alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setButtonType:type];
    [view setBezelStyle:bezelStyle];
    if (bezelStyle == NSRecessedBezelStyle) {
        // Interface Builder sets it up this way automatically
        [view setShowsBorderOnlyWhileMouseInside:YES];
    }
    [view setTitle:title];
    return view;
}

+ (NSButton *)buttonWithImageNamed:(NSString *)imageName type:(NSButtonType)type bezelStyle:(NSBezelStyle)bezelStyle {
    NSButton *view = [[self alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setButtonType:type];
    [view setBezelStyle:bezelStyle];
    if (bezelStyle == NSRecessedBezelStyle) {
        // Interface Builder sets it up this way automatically
        [view setShowsBorderOnlyWhileMouseInside:YES];
    }
    [view setImage:[NSImage imageNamed:imageName]];
    return view;
}

- (instancetype)withBezelStyle:(NSBezelStyle)bezelStyle {
    [self setBezelStyle:bezelStyle];
    return self;
}

- (instancetype)withNoBorder {
    [self setBordered:NO];
    return self;
}

- (instancetype)showingBorderOnlyWhenMouseInside {
    [self setShowsBorderOnlyWhileMouseInside:YES];
    return self;
}

@end


@implementation NSBox (ATMacViewCreation)

+ (NSBox *)box {
    NSBox *view = [[self alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.titlePosition = NSNoTitle;
    return view;
}

@end


@implementation NSControl (ATMacViewCreation)

- (instancetype)withTarget:(id)target action:(SEL)action {
    self.target = target;
    self.action = action;
    return self;
}

@end


@implementation NSView (ATMacViewCreation)

- (instancetype)addedToView:(NSView *)superview {
    [superview addSubview:self];
    return self;
}

@end
