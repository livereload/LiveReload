
#import "CompileFileActionRow.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"
#import "CompileFileAction.h"
#import "LRCheckboxOption.h"
#import "LRTextFieldOption.h"
#import "LRPopUpOption.h"
#import "LRCustomArgumentsOption.h"


@implementation CompileFileActionRow

- (void)loadContent {
    [super loadContent];

    self.sourcePopUp = [[[[NSPopUpButton popUpButton] withBezelStyle:NSRoundRectBezelStyle] withTarget:self action:@selector(sourceOptionSelected:)] addedToView:self];
    self.destinationPopUp = [[[[NSPopUpButton popUpButton] withBezelStyle:NSRoundRectBezelStyle] withTarget:self action:@selector(destinationOptionSelected:)] addedToView:self];

    [self addConstraintsWithVisualFormat:@"|-indentL2-[checkbox(>=200)]-[sourcePopUp(>=120)]-columnGapMin-[destinationPopUp(>=120)]-(>=buttonBarGapMin)-[optionsButton]-buttonGap-[removeButton]|" options:NSLayoutFormatAlignAllCenterY];
    [self addFullHeightConstraintsForSubview:self.sourcePopUp];

    //    [self alignView:self.checkbox toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.sourcePopUp toColumnNamed:@"from"];
    [self alignView:self.destinationPopUp toColumnNamed:@"to"];

    [self.checkbox bind:@"value" toObject:self.representedObject withKeyPath:@"enabled" options:nil];
}

- (void)updateContent {
    [super updateContent];
    self.checkbox.title = self.action.label;
}

- (void)updateFilterOptions {
    CompileFileAction *xaction = (CompileFileAction *)self.action;
    [self updateFilterOptionsPopUp:self.sourcePopUp selectedOption:self.action.inputFilterOption];
    [self updateFilterOptionsPopUp:self.destinationPopUp selectedOption:xaction.outputFilterOption];
}

- (IBAction)sourceOptionSelected:(NSPopUpButton *)sender {
    CompileFileAction *xaction = (CompileFileAction *)self.action;
    FilterOption *filterOption = sender.selectedItem.representedObject;

    BOOL same = ([xaction.inputFilterOption.subfolder isEqualToString:xaction.outputFilterOption.subfolder]);
    xaction.inputFilterOption = filterOption;
    if (same) {
        xaction.outputFilterOption = filterOption;
    }
}

- (IBAction)destinationOptionSelected:(NSPopUpButton *)sender {
    CompileFileAction *xaction = (CompileFileAction *)self.action;
    FilterOption *filterOption = sender.selectedItem.representedObject;
    xaction.outputFilterOption = filterOption;
}

+ (NSArray *)representedObjectKeyPathsToObserve {
    return @[@"inputFilterOption", @"outputFilterOption"];
}

- (void)loadOptionsIntoView:(LROptionsView *)container {
    LROption *option = [[LRCheckboxOption alloc] initWithOptionManifest:@{@"id": @"foo-bar", @"label": @"Foo Bar"}];
    option.action = self.action;
    [container addOption:option];

    option = [[LRTextFieldOption alloc] initWithOptionManifest:@{@"id": @"foo-boz", @"label": @"Bozz:", @"placeholder": @"boo boo"}];
    option.action = self.action;
    [container addOption:option];

    option = [[LRPopUpOption alloc] initWithOptionManifest:@{@"id": @"fubar", @"label": @"Fubar:", @"items": @[@{@"id": @"abc", @"label": @"Ab C"}, @{@"id": @"def", @"label": @"dEF"}]}];
    option.action = self.action;
    [container addOption:option];

    option = [[LRCustomArgumentsOption alloc] initWithOptionManifest:@{@"id": @"custom-args"}];
    option.action = self.action;
    [container addOption:option];
}

@end
