
#import "ATStackView.h"


@class OptionsRow;


@interface BaseActionRow : ATStackViewRow

@property (nonatomic, strong) IBOutlet NSButton *checkbox;
@property (nonatomic, strong) IBOutlet NSButton *optionsButton;
@property (nonatomic, strong) IBOutlet NSButton *removeButton;

@property (nonatomic, strong, readonly) OptionsRow *optionsRow;

@end
