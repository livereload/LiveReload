
#import <Foundation/Foundation.h>

@interface NSTextField (ATMacViewCreation)

+ (NSTextField *)staticLabelWithString:(NSString *)text;
+ (NSTextField *)staticLabelWithAttributedString:(NSAttributedString *)text;
+ (NSTextField *)editableField;

@end


@interface NSPopUpButton (ATMacViewCreation)

+ (NSPopUpButton *)popUpButton;
+ (NSPopUpButton *)pullDownButton;

@end


@interface NSButton (ATMacViewCreation)

+ (NSButton *)buttonWithTitle:(NSString *)title type:(NSButtonType)type bezelStyle:(NSBezelStyle)bezelStyle;
+ (NSButton *)buttonWithImageNamed:(NSString *)imageName type:(NSButtonType)type bezelStyle:(NSBezelStyle)bezelStyle;

- (instancetype)withBezelStyle:(NSBezelStyle)bezelStyle;
- (instancetype)withNoBorder;

@end


@interface NSControl (ATMacViewCreation)

- (instancetype)withTarget:(id)target action:(SEL)action;

@end


@interface NSView (ATMacViewCreation)

- (instancetype)addedToView:(NSView *)superview;

@end
