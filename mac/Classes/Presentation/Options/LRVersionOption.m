
#import "LRVersionOption.h"
#import "LRVersionSpec.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"
//#import "LRCommandLine.h"
#import "ATFunctionalStyle.h"


@interface LRVersionOption ()

@property(nonatomic, copy) NSArray *items;
@property(nonatomic, retain) NSPopUpButton *view;

@end


@implementation LRVersionOption

- (void)loadManifest {
    [super loadManifest];

    if (!self.label.length)
        [self addErrorMessage:@"Missing label"];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [[NSPopUpButton popUpButton] withTarget:self action:@selector(popUpSelectionDidChange:)];
    [_view addItemsWithTitles:[_items valueForKeyPath:@"label"]];
    [optionsView addOptionView:_view label:self.label flags:LROptionsViewFlagsLabelAlignmentBaseline];
    [self loadModelValues];
}

- (LRVersionSpec *)itemAtIndex:(NSInteger)index {
    return _items[index];
}

- (id)defaultValue {
    return self.action;
}

- (NSInteger)indexOfItemWithIdentifier:(NSString *)itemIdentifier {
    if (!itemIdentifier.length)
        return -1;

    NSInteger index = 0;
    for (LRVersionSpec *item in _items) {
        if ([item.stringValue isEqualToString:itemIdentifier]) {
            return index;
        }
        ++index;
    }
    return -1;
}

- (id)presentedValue {
    NSInteger index = [_view indexOfSelectedItem];
    if (index == -1)
        return self.defaultValue;
    return [self itemAtIndex:index].stringValue;
}

- (void)setPresentedValue:(id)value {
    [_view selectItemAtIndex:[self indexOfItemWithIdentifier:value]];
}

- (IBAction)popUpSelectionDidChange:(id)sender {
    [self presentedValueDidChange];
}

- (NSArray *)commandLineArguments {
    NSInteger index = [self indexOfItemWithIdentifier:self.effectiveValue];
    if (index == -1)
        return @[];
    return @[@"--botva"]; // [self itemAtIndex:index].arguments; // TODO FIXME
}

@end
