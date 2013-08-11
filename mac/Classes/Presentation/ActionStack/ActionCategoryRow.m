
#import "ActionCategoryRow.h"
#import "ATMacViewCreation.h"

@implementation ActionCategoryRow

- (id)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _titleLabel = [[NSTextField staticLabelWithString:title] addedToView:self];

        NSDictionary *bindings = NSDictionaryOfVariableBindings(_titleLabel);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_titleLabel]|" options:0 metrics:nil views:bindings]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_titleLabel]|" options:0 metrics:nil views:bindings]];
    }
    return self;
}

@end


@implementation CompilersCategoryRow : ActionCategoryRow
@end


@implementation FiltersCategoryRow : ActionCategoryRow
@end


@implementation ActionsCategoryRow : ActionCategoryRow
@end
