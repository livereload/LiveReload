
#import "LRVersionOption.h"
#import "LRVersionSpec.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"
#import "Action.h"
#import "LRContextActionType.h"

#import "ATFunctionalStyle.h"
#import "ATObservation.h"


@interface LRVersionOption ()

@property(nonatomic, copy) NSArray *items;
@property(nonatomic, retain) NSPopUpButton *view;

@end


@implementation LRVersionOption

- (void)loadManifest {
    [super loadManifest];

    if (!self.label.length)
        [self addErrorMessage:@"Missing label"];

    [self observeNotification:LRContextActionTypeDidChangeVersionsNotification withSelector:@selector(_updateVersionSpecs)];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [[NSPopUpButton popUpButton] withTarget:self action:@selector(popUpSelectionDidChange:)];
    [self _updateVersionSpecs];
    [optionsView addOptionView:_view label:self.label flags:LROptionsViewFlagsLabelAlignmentBaseline];
    [self loadModelValues];
}

- (LRVersionSpec *)itemAtIndex:(NSInteger)index {
    return _items[index];
}

- (id)defaultValue {
    return self.action;
}

- (NSInteger)indexOfItem:(LRVersionSpec *)query {
    if (!query)
        return -1;

    NSInteger index = 0;
    for (LRVersionSpec *item in _items) {
        if ([item isEqual:query]) {
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
    return [self itemAtIndex:index];
}

- (void)setPresentedValue:(id)value {
    [_view selectItemAtIndex:[self indexOfItem:value]];
}

- (id)modelValue {
    return self.action.primaryVersionSpec;
}

- (void)setModelValue:(id)modelValue {
    self.action.primaryVersionSpec = modelValue;
}

- (IBAction)popUpSelectionDidChange:(id)sender {
    [self presentedValueDidChange];
}

- (NSArray *)commandLineArguments {
    NSInteger index = [self indexOfItem:self.effectiveValue];
    if (index == -1)
        return @[];
    return @[];
}

- (void)_updateVersionSpecs {
    _items = self.action.contextActionType.versionSpecs;

    [_view removeAllItems];
    [_view addItemsWithTitles:[_items valueForKeyPath:@"title"]];
    [self loadModelValues];
}

@end
