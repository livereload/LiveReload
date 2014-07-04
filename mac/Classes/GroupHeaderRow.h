
#import "ATStackView.h"

@interface GroupHeaderRow : ATStackViewRow

@property(nonatomic, readonly) NSDictionary *metaInfo;
@property(nonatomic, strong) IBOutlet NSTextField *titleLabel;

@end


@interface CompilersCategoryRow : GroupHeaderRow
@end


@interface FiltersCategoryRow : GroupHeaderRow
@end
