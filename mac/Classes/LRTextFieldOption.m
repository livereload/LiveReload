@import LRCommons;
@import LRActionKit;

#import "LRTextFieldOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"


@interface LRTextFieldOption () <NSTextFieldDelegate>

@property(nonatomic, retain) TextOption *option;
@property(nonatomic, retain) NSTextField *view;

@end


@implementation LRTextFieldOption

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [NSTextField editableField];
    if (_option.placeholder.length > 0) {
        [_view.cell setPlaceholderString:_option.placeholder];
    }
    _view.delegate = self;
    [optionsView addOptionView:_view withLabel:self.label flags:LROptionsViewFlagsLabelAlignmentBaseline];
    [self loadModelValues];
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
