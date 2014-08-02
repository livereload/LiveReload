@import LRCommons;

#import "LRPopUpOption.h"
#import "ATMacViewCreation.h"
#import "LROptionsView.h"


@interface LRPopUpItem : NSObject

@property(nonatomic, readonly, copy) NSString *identifier;
@property(nonatomic, readonly, copy) NSString *label;
@property(nonatomic, readonly, copy) NSArray *arguments;

@end

@implementation LRPopUpItem

- (id)initWithIdentifier:(NSString *)identifier label:(NSString *)label arguments:(NSArray *)arguments {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _label = [label copy];
        _arguments = [arguments copy];
    }
    return self;
}

+ (id)popUpItemWithDictionary:(NSDictionary *)manifest {
    return [[self alloc] initWithIdentifier:manifest[@"id"] label:manifest[@"label"] arguments:P2ParseCommandLineSpec(manifest[@"args"])];
}

@end


@interface LRPopUpOption ()

@property(nonatomic, copy) NSArray *items;
@property(nonatomic, retain) NSPopUpButton *view;

@end


@implementation LRPopUpOption

- (void)loadManifest {
    [super loadManifest];

    _items = [self.manifest[@"items"] arrayByMappingElementsUsingBlock:^id(NSDictionary *spec) {
        if (![spec isKindOfClass:NSDictionary.class]) {
            [self addErrorMessage:@"Pop up item is not a dictionary"];
            return nil;
        }
        return [LRPopUpItem popUpItemWithDictionary:spec];
    }];

    if (!self.label.length)
        [self addErrorMessage:@"Missing label"];

    if (self.items.count == 0)
        [self addErrorMessage:@"Missing items"];

    [self.items enumerateObjectsUsingBlock:^(LRPopUpItem *item, NSUInteger idx, BOOL *stop) {
        if (0 == item.identifier.length) {
            [self addErrorMessage:[NSString stringWithFormat:@"Item %u is missing its identifier", (unsigned)idx]];
            *stop = YES;
        }
        if (0 == item.label.length) {
            [self addErrorMessage:[NSString stringWithFormat:@"Item %u is missing its label", (unsigned)idx]];
            *stop = YES;
        }
    }];
}

- (void)renderInOptionsView:(LROptionsView *)optionsView {
    _view = [[NSPopUpButton popUpButton] withTarget:self action:@selector(popUpSelectionDidChange:)];
    [_view addItemsWithTitles:[_items valueForKeyPath:@"label"]];
    [optionsView addOptionView:_view withLabel:self.label flags:LROptionsViewFlagsLabelAlignmentBaseline];
    [self loadModelValues];
}

- (LRPopUpItem *)itemAtIndex:(NSInteger)index {
    return _items[index];
}

- (id)defaultValue {
    return [self itemAtIndex:0].identifier;
}

- (NSInteger)indexOfItemWithIdentifier:(NSString *)itemIdentifier {
    if (!itemIdentifier.length)
        return -1;
    
    NSInteger index = 0;
    for (LRPopUpItem *item in _items) {
        if ([item.identifier isEqualToString:itemIdentifier]) {
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
    return [self itemAtIndex:index].identifier;
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
    return [self itemAtIndex:index].arguments;
}

@end
