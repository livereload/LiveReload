
#import "ATStackView.h"
#import "LROptionsView.h"


@class OptionsRow;


@interface BaseActionRow : ATStackViewRow

@property (nonatomic, strong) IBOutlet NSButton *checkbox;
@property (nonatomic, strong) IBOutlet NSButton *optionsButton;
@property (nonatomic, strong) IBOutlet NSButton *removeButton;

@property (nonatomic, strong, readonly) OptionsRow *optionsRow;

- (void)loadOptionsIntoView:(LROptionsView *)container;  // override point

@end
