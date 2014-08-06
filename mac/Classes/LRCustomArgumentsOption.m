//@import LRCommons;
//
//#import "LRCustomArgumentsOption.h"
//#import "LROptionsView.h"
//#import "LiveReload-Swift-x.h"
//
//
//@interface LRCustomArgumentsOption () <NSTextFieldDelegate>
//
//@property(nonatomic, retain) NSTextField *view;
//
//@end
//
//
//@implementation LRCustomArgumentsOption
//
//- (void)loadManifest {
//    [super loadManifest];
//}
//
//- (void)renderInOptionsView:(LROptionsView *)optionsView {
//    _view = [NSTextField editableField];
//    [_view.cell setPlaceholderString:@"--foo --bar=boz"];
//    _view.delegate = self;
//
//    [optionsView addOptionView:_view withLabel:@"Custom arguments:" flags:LROptionsViewFlagsLabelAlignmentBaseline];
//    [self loadModelValues];
//}
//
//- (id)defaultValue {
//    return @"";
//}
//
//- (id)presentedValue {
//    return _view.stringValue;
//}
//
//- (void)setPresentedValue:(id)value {
//    _view.stringValue = value;
//}
//
//- (id)modelValue {
//    return self.rule.customArgumentsString;
//}
//
//- (void)setModelValue:(id)modelValue {
//    self.rule.customArgumentsString = modelValue;
//}
//
//- (void)controlTextDidChange:(NSNotification *)obj {
//    [self presentedValueDidChange];
//}
//
//@end
