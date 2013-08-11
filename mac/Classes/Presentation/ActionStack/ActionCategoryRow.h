
#import "ATStackView.h"

@interface ActionCategoryRow : ATStackViewRow

- (id)initWithTitle:(NSString *)title;

@property(nonatomic, strong) IBOutlet NSTextField *titleLabel;

@end


@interface CompilersCategoryRow : ActionCategoryRow
@end


@interface FiltersCategoryRow : ActionCategoryRow
@end


@interface ActionsCategoryRow : ActionCategoryRow
@end
