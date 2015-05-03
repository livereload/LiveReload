@import Cocoa;


@interface NSTextField (ATMacViewCreation)

+ (NSTextField *)staticLabelWithString:(NSString *)text;
+ (NSTextField *)staticLabelWithString:(NSString *)text style:(NSDictionary *)style;
+ (NSTextField *)staticLabelWithAttributedString:(NSAttributedString *)text;
+ (NSTextField *)editableField;

- (instancetype)withStyle:(NSDictionary *)style;

@end


@interface NSTextView (ATMacViewCreation)

+ (NSTextView *)editableTextView;

@end


@interface NSPopUpButton (ATMacViewCreation)

+ (NSPopUpButton *)popUpButton;
+ (NSPopUpButton *)at_popUpButton;
+ (NSPopUpButton *)pullDownButton;

@end


@interface NSButton (ATMacViewCreation)

+ (NSButton *)buttonWithTitle:(NSString *)title type:(NSButtonType)type bezelStyle:(NSBezelStyle)bezelStyle;
+ (NSButton *)buttonWithImageNamed:(NSString *)imageName type:(NSButtonType)type bezelStyle:(NSBezelStyle)bezelStyle;

- (instancetype)withBezelStyle:(NSBezelStyle)bezelStyle;
- (instancetype)withNoBorder;
- (instancetype)showingBorderOnlyWhenMouseInside;

@end


@interface NSBox (ATMacViewCreation)

+ (NSBox *)box;

@end


@interface NSControl (ATMacViewCreation)

- (instancetype)withTarget:(id)target action:(SEL)action;

@end


@interface NSView (ATMacViewCreation)

+ (instancetype)containerView;

- (instancetype)addedToView:(NSView *)superview;

@end
