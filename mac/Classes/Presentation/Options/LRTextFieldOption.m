
#import "LRTextFieldOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"


@interface LRTextFieldOption () <NSTextFieldDelegate>

@property(nonatomic, copy) NSString *placeholder;
@property(nonatomic, retain) NSTextField *view;

@end


@implementation LRTextFieldOption

- (void)loadManifest {
    [super loadManifest];

    self.placeholder = self.manifest[@"placeholder"];

    if (!self.label.length)
        [self addErrorMessage:@"Missing label"];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [NSTextField editableField];
    if (_placeholder.length > 0) {
        [_view.cell setPlaceholderString:_placeholder];
    }
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
