@import LRCommons;

#import "ATStackView.h"


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

- (void)removeAllSubviews {
    NSArray *allLoadedRows = [self.subviews copy];
    for (ATStackViewRow *subview in allLoadedRows) {
        [subview removeFromSuperview];
    }
}

- (void)removeAllItems {
    NSArray *allLoadedRows = [self.subviews copy];
    for (ATStackViewRow *subview in allLoadedRows) {
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

- (ATStackViewRow *)addItem:(ATStackViewRow *)itemView {
    [self insertItem:itemView atIndex:_items.count];
    return itemView;
}

- (void)insertItem:(ATStackViewRow *)row atIndex:(NSInteger)index {
    [_items insertObject:row atIndex:index];
    [self addRowView:row];
    [self setNeedsUpdateConstraints:YES];
}

- (void)removeItem:(ATStackViewRow *)itemView {
    [self removeRowView:itemView];
    itemView.stackView = nil;
    [_items removeObject:itemView];

    for (ATStackViewRow *childRow in itemView.childRows) {
        [self removeItem:childRow];
    }
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

- (NSArray *)rowsOfClass:(Class)rowClass betweenRow:(ATStackViewRow *)leadingRow andRow:(ATStackViewRow *)trailingRow {
    NSInteger leadingIndex, trailingIndex;
    leadingIndex = [_items indexOfObject:leadingRow];
    NSAssert(leadingIndex != NSNotFound, @"Leading row not found: %@", leadingRow);
    trailingIndex = [_items indexOfObject:trailingRow];
    NSAssert(trailingIndex != NSNotFound, @"Trailing row not found: %@", leadingRow);

    NSAssert(leadingIndex < trailingIndex, @"Leading row must be before the trailing row, indexes: %d, %d", (int)leadingIndex, (int)trailingIndex);

    // 0 1 2 3 4 5 6 7
    //   L       T
    // with L=1, T=5, we want 3 rows (#2, #3, #4), so the count is T-L-1
    return [[_items subarrayWithRange:NSMakeRange(leadingIndex + 1, trailingIndex - leadingIndex - 1)] filteredArrayUsingBlock:^BOOL(id value) {
        return [value isKindOfClass:rowClass];
    }];
}

- (void)updateRowsOfClass:(Class)rowClass betweenRow:(ATStackViewRow *)leadingRow andRow:(ATStackViewRow *)trailingRow newRepresentedObjects:(NSArray *)representedObjects create:(ATStackViewCreateRowBlock)createBlock {

    NSArray *oldRows = [self rowsOfClass:rowClass betweenRow:leadingRow andRow:trailingRow];
    NSArray *oldRepresentedObjects = [oldRows arrayByMappingElementsToValueOfKeyPath:@"representedObject"];

    // remove deleted rows
    for (ATStackViewRow *row in oldRows) {
        if (![representedObjects containsObject:row.representedObject]) {
            [self removeItem:row];
        }
    }

    NSMutableArray *newRows = [NSMutableArray new];

    for (id representedObject in representedObjects) {
        NSInteger oldIndex = [oldRepresentedObjects indexOfObject:representedObject];
        if (oldIndex != NSNotFound) {
            [newRows addObject:oldRows[oldIndex]];
        } else {
            ATStackViewRow *row = createBlock(representedObject);
            if (row) {
                NSAssert([row isKindOfClass:rowClass], @"Added rows must be of the specified class %@, added row: %@", NSStringFromClass(rowClass), row);
                [newRows addObject:row];
            }
        }
    }

    [_items removeObjectsInArray:oldRows];
    NSInteger insertionIndex = [_items indexOfObject:leadingRow] + 1;
    [_items insertObjects:newRows atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertionIndex, newRows.count)]];

    [self removeAllSubviews];
    [self setNeedsUpdateConstraints:YES];  // will re-add any necessary row views
}

@end



@implementation ATStackViewRow {
    BOOL _contentLoaded;
    BOOL _collapsed;
    BOOL _updateContentRequired;
    BOOL _updateContentScheduled;
    NSMutableDictionary *_leadingAlignments;
    NSMutableDictionary *_trailingAlignments;
}

@synthesize leadingAlignments = _leadingAlignments;
@synthesize trailingAlignments = _trailingAlignments;


- (id)init {
    return [self initWithRepresentedObject:nil metrics:nil userInfo:nil delegate:nil];
}

- (id)initWithRepresentedObject:(id)representedObject metrics:(NSDictionary *)metrics userInfo:(NSDictionary *)userInfo delegate:(id)delegate {
    self = [super init];
    if (self) {
        _leadingAlignments = [NSMutableDictionary new];
        _trailingAlignments = [NSMutableDictionary new];
        _representedObject = representedObject;
        _metrics = metrics;
        _userInfo = (userInfo ? [userInfo copy] : [NSDictionary new]);
        _delegate = delegate;
        [self startObservingRepresentedObject];
        [self didUpdateUserInfo];
    }
    return self;
}

+ (id)rowWithRepresentedObject:(id)representedObject metrics:(NSDictionary *)metrics userInfo:(NSDictionary *)userInfo delegate:(id)delegate  {
    id result = [[[self class] alloc] initWithRepresentedObject:representedObject metrics:metrics userInfo:userInfo delegate:delegate];

    return result;
}

- (void)dealloc {
    [self stopObservingRepresentedObject];
}

- (NSDictionary *)AT_metrics {
    return self.metrics;
}

- (void)setUserInfo:(NSDictionary *)userInfo {
    if (_userInfo != userInfo) {
        _userInfo = (userInfo ? [userInfo copy] : [NSDictionary new]);
        [self didUpdateUserInfo];
    }
}

- (void)didUpdateUserInfo {
}

- (void)loadContentIfNeeded {
    if (!_contentLoaded) {
        _contentLoaded = YES;
        [self loadContent];
        [self updateContent];
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


#pragma mark -

void *ATStackViewRowObservationContext = "ATStackViewRowObservationContext";

+ (NSArray *)representedObjectKeyPathsToObserve {
    return @[];
}

- (void)startObservingRepresentedObject {
    for (NSString *keyPath in [self.class representedObjectKeyPathsToObserve]) {
        [self.representedObject addObserver:self forKeyPath:keyPath options:0 context:ATStackViewRowObservationContext];
    }
}

- (void)stopObservingRepresentedObject {
    for (NSString *keyPath in [self.class representedObjectKeyPathsToObserve]) {
        [self.representedObject removeObserver:self forKeyPath:keyPath context:ATStackViewRowObservationContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == ATStackViewRowObservationContext) {
        [self setNeedsUpdateContent];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark -

- (void)updateContentIfNeeded {
    if (_updateContentRequired) {
        _updateContentRequired = NO;
        [self updateContent];
    }
}

- (void)setNeedsUpdateContent {
    _updateContentRequired = YES;
    if (!_updateContentScheduled) {
        _updateContentScheduled = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            _updateContentScheduled = NO;
            [self updateContentIfNeeded];
        });
    }
}

- (void)updateContent {
}

@end
