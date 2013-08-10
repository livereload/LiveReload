
#import "ATStackView.h"

@implementation ATStackView {
    NSMutableArray *_items;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _items = [NSMutableArray new];
        _itemSpacing = 8.0;
        [self setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationVertical];
    }
    return self;
}

- (void)awakeFromNib {
    _items = [NSMutableArray new];
    _itemSpacing = 8.0;
    [self setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationVertical];
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)removeAllItems {
    for (NSView *subview in _items) {
        [subview removeFromSuperview];
    }
    [_items removeAllObjects];
}

- (void)addItem:(NSView *)itemView {
    [self insertItem:itemView atIndex:_items.count];
}

- (void)insertItem:(NSView *)itemView atIndex:(NSInteger)index {
    itemView.translatesAutoresizingMaskIntoConstraints = NO;

    [_items insertObject:itemView atIndex:index];
    [self addSubview:itemView];
    [self setNeedsUpdateConstraints:YES];
}

- (void)setItemSpacing:(CGFloat)itemSpacing {
    _itemSpacing = itemSpacing;
    [self setNeedsUpdateConstraints:YES];
}

//- (void)drawRect:(NSRect)dirtyRect {
//    [[NSColor redColor] set];
//    NSRectFill(self.bounds);
//}

- (void)updateConstraints {
    [super updateConstraints];
    
    [self removeConstraints:self.constraints];

    NSView *previous = nil;
    for (NSView *subview in _items) {
        CGSize fittingSize = subview.fittingSize;
//        NSLog(@"fittingSize = %@", NSStringFromSize(subview.fittingSize));
        [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:fittingSize.height]];

        if (previous)
            [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:previous attribute:NSLayoutAttributeBottom multiplier:1.0 constant:_itemSpacing]];
        else
//            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[subview]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subview)]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[subview]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subview)]];

        previous = subview;
    }

    if (previous)
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[previous]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previous)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:previous attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];

//    NSLog(@"Constraints: %@", self.constraints);
}


@end



@implementation ATStackViewRow

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

@end