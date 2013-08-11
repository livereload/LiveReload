
#import <Foundation/Foundation.h>
#import "ATStackView.h"
#import "ActionCategoryRow.h"


@interface ActionCategoriesGroup : ATStackViewGroup

@property(nonatomic, readonly, strong) CompilersCategoryRow *compilersCategory;
@property(nonatomic, readonly, strong) FiltersCategoryRow *filtersCategory;
@property(nonatomic, readonly, strong) ActionsCategoryRow *actionsCategory;

@end
