
#import "LRCustomArgumentsOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"
#import "Action.h"


@interface LRCustomArgumentsOption () <NSTextFieldDelegate>

@property(nonatomic, retain) NSTextField *view;

@end


@implementation LRCustomArgumentsOption

- (void)loadManifest {
    [super loadManifest];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [NSTextField editableField];
    [_view.cell setPlaceholderString:@"--foo --bar=boz"];
    _view.delegate = self;

    [optionsView addOptionView:_view withLabel:@"Custom arguments:" flags:LROptionsViewFlagsLabelAlignmentBaseline];
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

- (id)modelValue {
    return self.action.customArgumentsString;
}

- (void)setModelValue:(id)modelValue {
    self.action.customArgumentsString = modelValue;
}

- (void)controlTextDidChange:(NSNotification *)obj {
    [self presentedValueDidChange];
}

@end
