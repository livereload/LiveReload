
#import "ATStackView.h"
#import "ATAutolayout.h"


@interface ATStackViewRow ()

- (void)loadContentIfNeeded;

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

- (void)updateConstraints {
    [super updateConstraints];
    
    [self removeConstraints:self.constraints];

    NSMutableDictionary *leadingAlignments = [NSMutableDictionary dictionary];
    NSMutableDictionary *trailingAlignments = [NSMutableDictionary dictionary];

    ATStackViewRow *previous = nil;
    for (ATStackViewRow *subview in _items) {
        [subview loadContentIfNeeded];
        
        CGSize fittingSize = subview.fittingSize;
//        NSLog(@"fittingSize = %@", NSStringFromSize(subview.fittingSize));
        [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:fittingSize.height]];

        if (previous) {
            CGFloat spacing = MAX(previous.bottomMargin, subview.topMargin);
            [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:previous attribute:NSLayoutAttributeBottom multiplier:1.0 constant:spacing]];
        } else
//            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[subview]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subview)]];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];

        [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[subview]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(subview)]];

        [self alignViewsInDictionary:subview.leadingAlignments withPriorViewsInDictionary:leadingAlignments attribute:NSLayoutAttributeLeading];
        [self alignViewsInDictionary:subview.trailingAlignments withPriorViewsInDictionary:trailingAlignments attribute:NSLayoutAttributeTrailing];

        previous = subview;
    }

    if (previous)
//        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[previous]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(previous)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:previous attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];

//    NSLog(@"Constraints: %@", self.constraints);
}


@end



@implementation ATStackViewRow {
    BOOL _contentLoaded;
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
