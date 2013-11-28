
#import "LRVersionOption.h"
#import "LRVersionSpec.h"
#import "LROptionsView.h"
#import "Action.h"
#import "LRContextActionType.h"
#import "LRActionVersion.h"
#import "LRVersion.h"

#import "ATMacViewCreation.h"
#import "ATFunctionalStyle.h"
#import "ATObservation.h"


@interface LRVersionOption ()

@property(nonatomic, copy) NSArray *items;

@property(nonatomic, retain) NSView *containerView;
@property(nonatomic, retain) NSPopUpButton *popupView;
@property(nonatomic, retain) NSTextField *labelView;

@end


@implementation LRVersionOption

- (void)loadManifest {
    [super loadManifest];

    if (!self.label.length)
        [self addErrorMessage:@"Missing label"];

    [self observeNotification:LRContextActionTypeDidChangeVersionsNotification withSelector:@selector(_updateVersionSpecs)];
    [self observeProperty:@"action.effectiveVersion" withSelector:@selector(_updateEffectiveVersion)];
}

- (void)dealloc {
    [self removeAllObservations];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _containerView = [NSView containerView];
    _popupView = [[[NSPopUpButton popUpButton] withTarget:self action:@selector(popUpSelectionDidChange:)] addedToView:_containerView];
    _labelView = [[NSTextField staticLabelWithString:@""] addedToView:_containerView];
    NSDictionary *views = @{@"popupView": _popupView, @"labelView": _labelView};
    [_containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[popupView]-[labelView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
    [_containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[popupView]|" options:0 metrics:nil views:views]];

    [self _updateVersionSpecs];
    [self _updateEffectiveVersion];

    [optionsView addOptionView:_containerView label:self.label flags:LROptionsViewFlagsLabelAlignmentBaseline];
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
    NSInteger index = [_popupView indexOfSelectedItem];
    if (index == -1)
        return self.defaultValue;
    return [self itemAtIndex:index];
}

- (void)setPresentedValue:(id)value {
    [_popupView selectItemAtIndex:[self indexOfItem:value]];
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

    [_popupView removeAllItems];
    [_popupView addItemsWithTitles:[_items valueForKeyPath:@"title"]];
    [self loadModelValues];
}

- (void)_updateEffectiveVersion {
    _labelView.stringValue = [NSString stringWithFormat:@"(in use: %@)", self.action.effectiveVersion.primaryVersion.description ?: @"none"];
}

@end
