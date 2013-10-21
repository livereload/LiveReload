
#import "LRCheckboxOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"
#import "LRCommandLine.h"


@interface LRCheckboxOption ()

@property(nonatomic, retain) NSButton *view;

@property(nonatomic, copy) NSArray *argumentsWhenOn;
@property(nonatomic, copy) NSArray *argumentsWhenOff;

@end


@implementation LRCheckboxOption

- (void)loadManifest {
    [super loadManifest];

    _argumentsWhenOn = LRParseCommandLineSpec(self.manifest[@"args"]);
    _argumentsWhenOff = LRParseCommandLineSpec(self.manifest[@"args-off"]);

    if (!self.label.length)
        [self addErrorMessage:@"Missing label"];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [[NSButton buttonWithTitle:self.label type:NSSwitchButton bezelStyle:NSRoundRectBezelStyle] withTarget:self action:@selector(checkboxClicked:)];
    [optionsView addOptionView:_view label:@"" flags:LROptionsViewFlagsLabelAlignmentBaseline];
    [self loadModelValues];
}

- (IBAction)checkboxClicked:(id)sender {
    [self presentedValueDidChange];
}

- (id)defaultValue {
    return @(NO);
}

- (id)presentedValue {
    return (_view.state == NSOnState ? @(YES) : @(NO));
}

- (void)setPresentedValue:(id)value {
    _view.state = ([value boolValue] ? NSOnState : NSOffState);
}

- (NSArray *)commandLineArguments {
    return [self.effectiveValue boolValue] ? _argumentsWhenOn : _argumentsWhenOff;
}

@end
