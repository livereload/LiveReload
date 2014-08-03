@import LRCommons;
@import LRActionKit;

#import "LRPopUpOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"


@interface LRPopUpOption ()

@property(nonatomic, readonly) MultipleChoiceOption *option;
@property(nonatomic, retain) NSPopUpButton *view;

@end


@implementation LRPopUpOption

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [[NSPopUpButton popUpButton] withTarget:self action:@selector(popUpSelectionDidChange:)];
    [_view addItemsWithTitles:[_option.items valueForKeyPath:@"label"]];
    [optionsView addOptionView:_view withLabel:self.label flags:LROptionsViewFlagsLabelAlignmentBaseline];
    [self loadModelValues];
}

- (MultipleChoiceOptionItem *)itemAtIndex:(NSInteger)index {
    return _option.items[index];
}

- (id)presentedValue {
    NSInteger index = [_view indexOfSelectedItem];
    if (index == -1)
        return self.defaultValue;
    return [self itemAtIndex:index].identifier;
}

- (void)setPresentedValue:(id)value {
    [_view selectItemAtIndex:[_option findItemWithIdentifier:value].index];
}

- (IBAction)popUpSelectionDidChange:(id)sender {
    [self presentedValueDidChange];
}

@end
