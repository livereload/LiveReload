
#import "LRTextFieldOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"


@interface LRTextFieldOption () <NSTextFieldDelegate>

@property(nonatomic, copy) NSString *label;
@property(nonatomic, retain) NSTextField *view;

@end


@implementation LRTextFieldOption

- (void)loadManifest {
    [super loadManifest];
    if (!self.label.length)
        [self addErrorMessage:@"Missing label"];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [NSTextField editableField];
    _view.delegate = self;
    [optionsView addOptionView:_view label:self.label flags:LROptionsViewFlagsLabelAlignmentBaseline];
    [self loadModelValues];
}

- (id)defaultValue {
    return @"";
}

- (id)presentedValue {
    return _view.stringValue;
}

- (void)setPresentedValue:(id)value {
    _view.stringValue = value;
}

- (void)controlTextDidChange:(NSNotification *)obj {
    [self presentedValueDidChange];
}

@end
