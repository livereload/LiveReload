#import "ATStackView.h"
#import "LROptionsView.h"


typedef void (^OptionsRowLoadContentBlock)();


@interface OptionsRow : ATStackViewRow

@property(nonatomic, strong, readonly) NSBox *box;
@property(nonatomic, strong, readonly) LROptionsView *optionsView;
@property(nonatomic, strong) OptionsRowLoadContentBlock loadContentBlock;

@end
