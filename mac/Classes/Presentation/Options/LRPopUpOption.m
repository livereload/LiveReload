
#import "LRPopUpOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"


@interface LRPopUpOption ()

@property(nonatomic, copy) NSArray *items;
@property(nonatomic, retain) NSPopUpButton *view;

@end


@implementation LRPopUpOption

- (void)loadManifest {
    [super loadManifest];

    _items = [self.manifest[@"items"] copy];

    if (!self.label.length)
        [self addErrorMessage:@"Missing label"];

    if (self.items.count == 0)
        [self addErrorMessage:@"Missing items"];

    [self.items enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
        if (![item isKindOfClass:NSDictionary.class]) {
            [self addErrorMessage:[NSString stringWithFormat:@"Item %u is not a dictionary", (unsigned)idx]];
            *stop = YES;
        }
    }];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [[NSPopUpButton popUpButton] withTarget:self action:@selector(popUpSelectionDidChange:)];
    [_view addItemsWithTitles:[_items valueForKeyPath:@"label"]];
    [optionsView addOptionView:_view label:self.label flags:LROptionsViewFlagsLabelAlignmentBaseline];
    [self loadModelValues];
}

- (NSDictionary *)itemAtIndex:(NSInteger)index {
    return _items[index];
}

- (id)defaultValue {
    return [self itemAtIndex:0][@"id"];
}

- (NSInteger)indexOfItemWithIdentifier:(NSString *)itemIdentifier {
    if (!itemIdentifier.length)
        return -1;
    
    NSInteger index = 0;
    for (NSDictionary *item in _items) {
        if ([item[@"id"] isEqualToString:itemIdentifier]) {
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
    return [self itemAtIndex:index][@"id"];
}

- (void)setPresentedValue:(id)value {
    [_view selectItemAtIndex:[self indexOfItemWithIdentifier:value]];
}

- (IBAction)popUpSelectionDidChange:(id)sender {
    [self presentedValueDidChange];
}

@end
