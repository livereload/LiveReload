
#import "ActionCategoryItems.h"

@implementation ActionCategoriesGroup

- (id)init {
    self = [super init];
    if (self) {
        _compilersCategory = [[CompilersCategoryRow alloc] initWithTitle:NSLocalizedString(@"Compilers:", nil)];
        _filtersCategory = [[FiltersCategoryRow alloc] initWithTitle:NSLocalizedString(@"Filters:", nil)];
        _actionsCategory = [[ActionsCategoryRow alloc] initWithTitle:NSLocalizedString(@"Actions:", nil)];
    }
    return self;
}

- (NSArray *)children {
    return @[_compilersCategory, _filtersCategory, _actionsCategory];
}

@end
