
#import "LROptionsView.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"
#import "LROption.h"


#define kVerticalPadding 0
#define kHorizontalPadding 0
#define kVerticalSpacing 8
#define kTypicalLabelWidth 80
#define kTopLabelBaselineOffset 16


@implementation LROptionsView {
    NSView *_lastOptionView;
    NSLayoutConstraint *_bottomConstraint;
    NSMutableArray *_options;
}

+ (LROptionsView *)optionsView {
    LROptionsView *view = [[self alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _options = [NSMutableArray new];
    }
    return self;
}

- (void)addOptionView:(NSView *)optionView withLabel:(NSString *)label flags:(LROptionsViewFlags)flags {
    [self addOptionView:optionView withLabel:label alignedToView:optionView flags:flags];
}

- (void)addOptionView:(NSView *)optionView withLabel:(NSString *)label alignedToView:(NSView *)labelAlignmentView flags:(LROptionsViewFlags)flags {
    optionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:optionView];

    NSDictionary *metrics = @{@"verticalPadding": @kVerticalPadding, @"horizontalPadding": @kHorizontalPadding};

    if (_lastOptionView)
        // vertical spacing between optionView and lastOptionView
        [self addConstraint:[NSLayoutConstraint constraintWithItem:optionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_lastOptionView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:kVerticalSpacing]];
    else
        // top padding
        [self addConstraint:[NSLayoutConstraint constraintWithItem:optionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:kVerticalPadding]];

    // horizontal centering (breakable, so that it can shift to the right if the space is tight and some labels are very long)
    [self addConstraint:[[NSLayoutConstraint constraintWithItem:optionView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:-(kTypicalLabelWidth/2)] withPriority:200]];

    // right edge
    [self addConstraint:[NSLayoutConstraint constraintWithItem:optionView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-kHorizontalPadding]];

    // anything with content hugging priority < LROptionsViewRightEdgeExpansionPriority (100) will expand to the right edge
    [self addConstraint:[[NSLayoutConstraint constraintWithItem:optionView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-kHorizontalPadding] withPriority:LROptionsViewRightEdgeExpansionPriority]];

    // align left edges of all option views (so that if some have to be moved, all of them are moved)
    if (_lastOptionView)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:optionView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:_lastOptionView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];

    if (label) {
        NSTextField *labelView = [NSTextField staticLabelWithString:label];
        labelView.alignment = NSRightTextAlignment;
        [self addSubview:labelView];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-(>=horizontalPadding)-[labelView]-[optionView]" options:0 metrics:metrics views:NSDictionaryOfVariableBindings(labelView, optionView)]];

        if ((flags & LROptionsViewFlagsLabelAlignmentMask) == LROptionsViewFlagsLabelAlignmentBaseline)
            [self addConstraint:[[NSLayoutConstraint constraintWithItem:labelView attribute:NSLayoutAttributeBaseline relatedBy:NSLayoutRelationEqual toItem:labelAlignmentView attribute:NSLayoutAttributeBaseline multiplier:1.0 constant:0] withPriority:NSLayoutPriorityDefaultHigh]];
        else if ((flags & LROptionsViewFlagsLabelAlignmentMask) == LROptionsViewFlagsLabelAlignmentCenter)
            [self addConstraint:[[NSLayoutConstraint constraintWithItem:labelView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:labelAlignmentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0] withPriority:NSLayoutPriorityDefaultHigh]];

        if ((flags & LROptionsViewFlagsLabelAlignmentMask) == LROptionsViewFlagsLabelAlignmentTop) {
            [self addConstraint:[NSLayoutConstraint constraintWithItem:labelView attribute:NSLayoutAttributeBaseline relatedBy:NSLayoutRelationEqual toItem:optionView attribute:NSLayoutAttributeTop multiplier:1.0 constant:kTopLabelBaselineOffset]];
        }
}

    // bottom padding
    if (_bottomConstraint)
        [self removeConstraint:_bottomConstraint];
    _bottomConstraint = [NSLayoutConstraint constraintWithItem:optionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:kVerticalPadding];
    [self addConstraint:_bottomConstraint];

    _lastOptionView = optionView;
}

- (void)addOption:(LROption *)option {
    [_options addObject:option];
    [option renderInOptionsView:self];
}

@end
