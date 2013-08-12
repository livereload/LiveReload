
#import "ATStackView.h"
#import "ATAutolayout.h"


@interface ATStackView ()

- (void)noteRowChanged:(ATStackViewRow *)row;

@end


@interface ATStackViewRow ()

@property(nonatomic, weak) ATStackView *stackView;
@property(nonatomic, readonly) NSDictionary *leadingAlignments;
@property(nonatomic, readonly) NSDictionary *trailingAlignments;

@end


@implementation ATStackView {
    NSMutableArray *_items;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _items = [NSMutableArray new];
        [self setContentHuggingPriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationVertical];
    }
    return self;
}

+ (BOOL)requiresConstraintBasedLayout {
    return YES;
}

- (void)removeAllItems {
    for (ATStackViewRow *subview in _items) {
        [subview removeFromSuperview];
        subview.stackView = nil;
    }
    [_items removeAllObjects];
}

- (void)addRowView:(ATStackViewRow *)row {
    row.stackView = self;
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:row];
}

- (void)removeRowView:(ATStackViewRow *)row {
    [row removeFromSuperview];
}

- (void)addItem:(ATStackViewRow *)itemView {
    [self insertItem:itemView atIndex:_items.count];
}

- (void)insertItem:(ATStackViewRow *)row atIndex:(NSInteger)index {
    [_items insertObject:row atIndex:index];
    [self addRowView:row];
    [self setNeedsUpdateConstraints:YES];
}


//- (void)drawRect:(NSRect)dirtyRect {
//    [[NSColor redColor] set];
//    NSRectFill(self.bounds);
//}

- (void)alignViewsInDictionary:(NSDictionary *)alignments withPriorViewsInDictionary:(NSMutableDictionary *)priorAlignments attribute:(NSLayoutAttribute)attribute {
    [alignments enumerateKeysAndObjectsUsingBlock:^(NSString *columnName, NSView *view, BOOL *stop) {
        NSView *priorView = priorAlignments[columnName];
        if (priorView) {
            [self addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:attribute relatedBy:NSLayoutRelationEqual toItem:priorView attribute:attribute multiplier:1.0 constant:0.0]];
        }
    }];

    [priorAlignments setValuesForKeysWithDictionary:alignments];
}

- (void)updateConstraintsForRow:(ATStackViewRow *)row leadingAlignments:(NSMutableDictionary *)leadingAlignments trailingAlignments:(NSMutableDictionary *)trailingAlignments previousRow:(ATStackViewRow **)previousRowPtr {
    if (row.collapsed)
        return;

    // add child row views
    if (row.superview == nil) {
        [self addRowView:row];
    }

    [row loadContentIfNeeded];

//    CGSize fittingSize = row.fittingSize;
    //        NSLog(@"fittingSize = %@", NSStringFromSize(subview.fittingSize));
//    [self addConstraint:[NSLayoutConstraint constraintWithItem:row attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:fittingSize.height]];

    ATStackViewRow *previousRow = *previousRowPtr;
    if (previousRow) {
        CGFloat spacing = MAX(previousRow.bottomMargin, row.topMargin);
        [self addConstraint:[NSLayoutConstraint constraintWithItem:row attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:previousRow attribute:NSLayoutAttributeBottom multiplier:1.0 constant:spacing]];
    } else
        //            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[subview]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subview)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:row attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:row attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:row attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    //        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[subview]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subview)]];

    [self alignViewsInDictionary:row.leadingAlignments withPriorViewsInDictionary:leadingAlignments attribute:NSLayoutAttributeLeading];
    [self alignViewsInDictionary:row.trailingAlignments withPriorViewsInDictionary:trailingAlignments attribute:NSLayoutAttributeTrailing];

    *previousRowPtr = row;

    for (ATStackViewRow *child in row.childRows) {
        [self updateConstraintsForRow:child leadingAlignments:leadingAlignments trailingAlignments:trailingAlignments previousRow:previousRowPtr];
    }
}

- (void)updateConstraints {
    [super updateConstraints];
    
    [self removeConstraints:self.constraints];

    NSMutableDictionary *leadingAlignments = [NSMutableDictionary dictionary];
    NSMutableDictionary *trailingAlignments = [NSMutableDictionary dictionary];
    ATStackViewRow *previousRow = nil;

    for (ATStackViewRow *row in _items) {
        [self updateConstraintsForRow:row leadingAlignments:leadingAlignments trailingAlignments:trailingAlignments previousRow:&previousRow];
    }

    if (previousRow)
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[previous]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previous)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:previousRow attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];

//    NSLog(@"Constraints: %@", self.constraints);
}

- (void)noteRowChanged:(ATStackViewRow *)row {
    BOOL collapsed = row.collapsed;
    BOOL added = (row.superview != nil);
    if (collapsed && added) {
        [self removeRowView:row];
    } else if (!collapsed && !added) {
        [self addRowView:row];
    }
    [self setNeedsUpdateConstraints:YES];
}

@end



@implementation ATStackViewRow {
    BOOL _contentLoaded;
    BOOL _collapsed;
    NSMutableDictionary *_leadingAlignments;
    NSMutableDictionary *_trailingAlignments;
}

@synthesize leadingAlignments = _leadingAlignments;
@synthesize trailingAlignments = _trailingAlignments;


- (id)init {
    return [self initWithRepresentedObject:nil metrics:nil delegate:nil];
}

- (id)initWithRepresentedObject:(id)representedObject metrics:(NSDictionary*)metrics delegate:(id)delegate {
    self = [super init];
    if (self) {
        _leadingAlignments = [NSMutableDictionary new];
        _trailingAlignments = [NSMutableDictionary new];
        _representedObject = representedObject;
        _metrics = metrics;
        _delegate = delegate;
    }
    return self;
}

+ (id)rowWithRepresentedObject:(id)representedObject metrics:(NSDictionary*)metrics delegate:(id)delegate  {
    id result = [[[self class] alloc] initWithRepresentedObject:representedObject metrics:metrics delegate:delegate];

    return result;
}

- (NSDictionary *)AT_metrics {
    return self.metrics;
}

- (void)loadContentIfNeeded {
    if (!_contentLoaded) {
        _contentLoaded = YES;
        [self loadContent];
    }
}

- (void)loadContent {
}

- (void)alignView:(NSView *)view toColumnNamed:(NSString *)columnName {
    [self alignView:view toColumnNamed:columnName alignment:ATStackViewColumnAlignmentBothSides];
}

- (void)alignView:(NSView *)view toColumnNamed:(NSString *)columnName alignment:(ATStackViewColumnAlignment)alignment {
    if (alignment == ATStackViewColumnAlignmentLeading || alignment == ATStackViewColumnAlignmentBothSides) {
        _leadingAlignments[columnName] = view;
    }
    if (alignment == ATStackViewColumnAlignmentTrailing || alignment == ATStackViewColumnAlignmentBothSides) {
        _trailingAlignments[columnName] = view;
    }
}

- (BOOL)isCollapsed {
    return _collapsed;
}

- (void)setCollapsed:(BOOL)collapsed {
    [self setCollapsed:collapsed animated:NO];
}

- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated {
    if (_collapsed != collapsed) {
        _collapsed = collapsed;
        [self.stackView noteRowChanged:self];
    }
}

- (void)setChildRows:(NSArray *)childRows {
    if (_childRows != childRows) {
        for (ATStackViewRow *childRow in _childRows) {
            childRow.stackView = nil;
        }
        _childRows = childRows;
        for (ATStackViewRow *childRow in _childRows) {
            childRow.stackView = _stackView;
        }
    }
}

- (void)setStackView:(ATStackView *)stackView {
    if (_stackView != stackView) {
        _stackView = stackView;
        for (ATStackViewRow *childRow in _childRows) {
            childRow.stackView = _stackView;
        }
    }
}

- (void)updateConstraints {
    [self loadContentIfNeeded];
    [super updateConstraints];
}

@end


@implementation ATStackViewGroup

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSArray *)children {
    return @[];
}

@end

@implementation ATStackViewMappedGroup
- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSArray *)items {
    return @[];
}

- (ATStackViewRow *)newRowForItem:(id)item {
    return nil;
}

@end
