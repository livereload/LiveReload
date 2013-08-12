
#import "OptionsRow.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"

@implementation OptionsRow {
    NSBox *_box;
    NSView *_contentView;
}

- (NSBox *)box {
    if (!_box) {
        _box = [[NSBox box] addedToView:self];
    }
    return _box;
}

- (void)loadContent {
    [super loadContent];

    NSTextField *label = [[NSTextField staticLabelWithString:@"TODO: options"] addedToView:self.box];
    [self.box addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[label]-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
    [self.box addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[label]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(label)]];
//    [self.box addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.box attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
//    [self.box addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.box attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];

    [self addConstraintsWithVisualFormat:@"|-indentL3-[box]|"];
    [self addConstraintsWithVisualFormat:@"V:|[box]|"];

    self.topMargin = 8;
    self.bottomMargin = 16;
}

@end
