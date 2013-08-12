
#import "BaseActionRow.h"
#import "OptionsRow.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"

@implementation BaseActionRow {
    OptionsRow *_optionsRow;
}

- (void)loadContent {
    self.topMargin = self.bottomMargin = 8;

    self.childRows = @[self.optionsRow];
}

- (NSButton *)checkbox {
    return _checkbox ?: (_checkbox = [[NSButton buttonWithTitle:@"" type:NSSwitchButton bezelStyle:NSRoundRectBezelStyle] addedToView:self]);
}

- (NSButton *)optionsButton {
    if (!_optionsButton) {
        _optionsButton = [[[NSButton buttonWithImageNamed:@"LROptionsTemplate" type:NSPushOnPushOffButton bezelStyle:NSRecessedBezelStyle] withTarget:self action:@selector(optionsClicked:)] addedToView:self];
    }
    return _optionsButton;
}

- (NSButton *)removeButton {
    return _removeButton ?: (_removeButton = [[[NSButton buttonWithImageNamed:@"NSRemoveTemplate" type:NSPushOnPushOffButton bezelStyle:NSRecessedBezelStyle] withTarget:self action:@selector(removeClicked:)] addedToView:self]);
}

- (OptionsRow *)optionsRow {
    if (!_optionsRow) {
        _optionsRow = [OptionsRow rowWithRepresentedObject:self.representedObject metrics:self.metrics delegate:self];
        _optionsRow.collapsed = YES;

        __weak BaseActionRow *myself = self;
        _optionsRow.loadContentBlock = ^{
            [myself _loadOptions];
        };
    }
    return _optionsRow;
}

- (IBAction)optionsClicked:(id)sender {
    BOOL collapse = (self.optionsButton.state != NSOnState);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.optionsRow setCollapsed:collapse animated:YES];
    });
}

- (IBAction)removeClicked:(id)sender {
    //    [_delegate didInvokeRemoveInActionRowView:self];
}

- (void)_loadOptions {
    [self loadOptionsIntoView:_optionsRow.optionsView];
}

- (void)loadOptionsIntoView:(LROptionsView *)container {
}

@end
