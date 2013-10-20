
#import "LRCheckboxOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"


@interface LRCheckboxOption ()

@property(nonatomic, retain) NSButton *view;

@end


@implementation LRCheckboxOption

- (void)loadManifest {
    [super loadManifest];
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

@end
