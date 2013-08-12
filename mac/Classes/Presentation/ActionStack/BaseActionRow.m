
#import "BaseActionRow.h"
#import "ATMacViewCreation.h"

@implementation BaseActionRow

- (void)loadContent {
    self.topMargin = self.bottomMargin = 8;
}

- (NSButton *)checkbox {
    return _checkbox ?: (_checkbox = [[NSButton buttonWithTitle:@"" type:NSSwitchButton bezelStyle:NSRoundRectBezelStyle] addedToView:self]);
}

- (NSButton *)optionsButton {
    return _optionsButton ?: (_optionsButton = [[[NSButton buttonWithImageNamed:@"LROptionsTemplate" type:NSPushOnPushOffButton bezelStyle:NSRecessedBezelStyle] withTarget:self action:@selector(optionsClicked:)] addedToView:self]);
}

- (NSButton *)removeButton {
    return _removeButton ?: (_removeButton = [[[NSButton buttonWithImageNamed:@"NSRemoveTemplate" type:NSPushOnPushOffButton bezelStyle:NSRecessedBezelStyle] withTarget:self action:@selector(removeClicked:)] addedToView:self]);
}

- (IBAction)optionsClicked:(id)sender {
}

- (IBAction)removeClicked:(id)sender {
    //    [_delegate didInvokeRemoveInActionRowView:self];
}

@end
