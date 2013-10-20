
#import "LRCheckboxOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"


@interface LRCheckboxOption ()

@property(nonatomic, copy) NSString *title;
@property(nonatomic, retain) NSButton *view;

@end


@implementation LRCheckboxOption

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [[NSButton buttonWithTitle:self.title type:NSSwitchButton bezelStyle:NSRoundRectBezelStyle] withTarget:self action:@selector(checkboxClicked:)];
    [optionsView addOptionView:_view label:@"" flags:LROptionsViewFlagsLabelAlignmentBaseline];
    [self loadModelValues];
}

- (void)loadManifest {
    [super loadManifest];
    _title = self.manifest[@"title"];
    if (!_title.length)
        [self addErrorMessage:@"Missing title"];
}
- (void)loadModelValues {
    [super loadModelValues];
//    _view.state =
}
- (void)saveModelValues {
    [super saveModelValues];
}

- (IBAction)checkboxClicked:(id)sender {
    [self saveModelValues];
}

@end
