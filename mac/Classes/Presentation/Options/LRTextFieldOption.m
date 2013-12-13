
#import "LRTextFieldOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"
#import "LRCommandLine.h"
#import "NSArray+ATSubstitutions.h"


@interface LRTextFieldOption () <NSTextFieldDelegate>

@property(nonatomic, copy) NSString *placeholder;
@property(nonatomic, retain) NSTextField *view;

@property(nonatomic, copy) NSArray *arguments;
@property(nonatomic) BOOL skipArgumentsIfEmpty;

@end


@implementation LRTextFieldOption

- (void)loadManifest {
    [super loadManifest];

    self.placeholder = self.manifest[@"placeholder"];

    self.arguments = LRParseCommandLineSpec(self.manifest[@"args"]);
    self.skipArgumentsIfEmpty = (self.manifest[@"skip-if-empty"] ? [self.manifest[@"skip-if-empty"] boolValue] : YES);

    if (!self.label.length)
        [self addErrorMessage:@"Missing label"];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [NSTextField editableField];
    if (_placeholder.length > 0) {
        [_view.cell setPlaceholderString:_placeholder];
    }
    _view.delegate = self;
    [optionsView addOptionView:_view withLabel:self.label flags:LROptionsViewFlagsLabelAlignmentBaseline];
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

- (NSArray *)commandLineArguments {
    NSString *value = (NSString *)self.effectiveValue;
    if (value.length == 0 && self.skipArgumentsIfEmpty)
        return @[];

    return [self.arguments arrayBySubstitutingValuesFromDictionary:@{@"$(value)": value}];
}

@end
