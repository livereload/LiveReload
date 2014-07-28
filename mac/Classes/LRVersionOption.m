
#import "LRVersionOption.h"
#import "LRVersionSpec.h"
#import "LROptionsView.h"
#import "LiveReload-Swift-x.h"
#import "LRContextAction.h"
#import "LRActionVersion.h"
@import PiiVersionKit;

#import "ATMacViewCreation.h"
#import "ATFunctionalStyle.h"
@import LRCommons;


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

    [self observeNotification:LRContextActionDidChangeVersionsNotification withSelector:@selector(_updateVersionSpecs)];
    [self observeProperty:@"rule.effectiveVersion" withSelector:@selector(_updateEffectiveVersion)];
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

    [optionsView addOptionView:_containerView withLabel:self.label alignedToView:_popupView flags:LROptionsViewFlagsLabelAlignmentBaseline];
    [self loadModelValues];
}

- (LRVersionSpec *)itemAtIndex:(NSInteger)index {
    return _items[index];
}

- (id)defaultValue {
    return self.rule;
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
    NSMenuItem *menuItem = _popupView.selectedItem;
    return menuItem.representedObject;
}

- (void)setPresentedValue:(id)value {
    [_popupView selectItemWithTag:1+[self indexOfItem:value]];
}

- (id)modelValue {
    return self.rule.primaryVersionSpec;
}

- (void)setModelValue:(id)modelValue {
    self.rule.primaryVersionSpec = modelValue;
}

- (IBAction)popUpSelectionDidChange:(id)sender {
    [self presentedValueDidChange];
}

- (NSArray *)commandLineArguments {
    return @[];
}

- (NSArray *)menuItemsArrayByAddingSeparatorsBetweenGroups:(NSArray *)menuItemGroups {
    NSMutableArray *result = [NSMutableArray new];
    BOOL separatorRequired = NO;
    for (NSArray *menuItems in menuItemGroups) {
        if (menuItems.count == 0)
            continue;
        if (separatorRequired)
            [result addObject:[NSMenuItem separatorItem]];
        [result addObjectsFromArray:menuItems];
        separatorRequired = YES;
    }
    return [result copy];
}

- (void)_updateVersionSpecs {
    _items = self.rule.contextAction.versionSpecs;

    NSMenuItem *(^createItem)(LRVersionSpec *spec, NSInteger index) = ^NSMenuItem *(LRVersionSpec *spec, NSInteger index) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:spec.title action:NULL keyEquivalent:@""];
        item.representedObject = spec;
        item.tag = 1+index;
        return item;
    };

    NSMutableArray *group1 = [NSMutableArray new];
    NSMutableArray *group2 = [NSMutableArray new];
    NSMutableArray *group3 = [NSMutableArray new];
    NSMutableArray *group4 = [NSMutableArray new];
    NSMutableArray *group5 = [NSMutableArray new];

    NSInteger index = 0;
    for (LRVersionSpec *spec in _items) {
        switch (spec.type) {
            case LRVersionSpecTypeStableAny:
                [group1 addObject:createItem(spec, index)];
                break;
            case LRVersionSpecTypeStableMajor:
                [group2 addObject:createItem(spec, index)];
                break;
            case LRVersionSpecTypeMajorMinor:
                [group3 addObject:createItem(spec, index)];
                break;
            case LRVersionSpecTypeSpecific:
                [group4 addObject:createItem(spec, index)];
                break;
            case LRVersionSpecTypeUnknown:
                [group5 addObject:createItem(spec, index)];
                break;
        }
        ++index;
    }

    [_popupView removeAllItems];
    for (NSMenuItem *menuItem in [self menuItemsArrayByAddingSeparatorsBetweenGroups:@[group1, group2, group3, group4, group5]]) {
        [_popupView.menu addItem:menuItem];
    }

    [self loadModelValues];
}

- (void)_updateEffectiveVersion {
    _labelView.stringValue = [NSString stringWithFormat:@"(in use: %@)", self.rule.effectiveVersion.primaryVersion.description ?: @"none"];
}

@end
