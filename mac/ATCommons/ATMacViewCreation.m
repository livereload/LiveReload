
#import "ATMacViewCreation.h"

@implementation NSTextField (ATMacViewCreation)

+ (NSTextField *)staticLabelWithString:(NSString *)text {
    NSTextField *view = [[NSTextField alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setBordered:NO];
    [view setEditable:NO];
    [view setDrawsBackground:NO];
    [view setStringValue:text];
    return view;
}

+ (NSTextField *)staticLabelWithAttributedString:(NSAttributedString *)text {
    NSTextField *view = [[NSTextField alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setBordered:NO];
    [view setEditable:NO];
    [view setAttributedStringValue:text];
    return view;
}

+ (NSTextField *)editableField {
    NSTextField *view = [[NSTextField alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

@end


@implementation NSPopUpButton (ATMacViewCreation)

+ (NSPopUpButton *)popUpButton {
    NSPopUpButton *view = [[NSPopUpButton alloc] initWithFrame:CGRectZero pullsDown:NO];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

+ (NSPopUpButton *)pullDownButton {
    NSPopUpButton *view = [[NSPopUpButton alloc] initWithFrame:CGRectZero pullsDown:YES];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

@end


@implementation NSButton (ATMacViewCreation)

+ (NSButton *)buttonWithTitle:(NSString *)title type:(NSButtonType)type bezelStyle:(NSBezelStyle)bezelStyle {
    NSButton *view = [[NSButton alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setButtonType:type];
    [view setBezelStyle:bezelStyle];
    [view setTitle:title];
    return view;
}

+ (NSButton *)buttonWithImageNamed:(NSString *)imageName type:(NSButtonType)type bezelStyle:(NSBezelStyle)bezelStyle {
    NSButton *view = [[NSButton alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view setButtonType:type];
    [view setBezelStyle:bezelStyle];
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

@end


@implementation NSBox (ATMacViewCreation)

+ (NSBox *)box {
    NSBox *view = [[NSBox alloc] initWithFrame:CGRectZero];
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
