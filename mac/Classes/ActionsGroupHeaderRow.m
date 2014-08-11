@import LRCommons;

#import "ActionsGroupHeaderRow.h"


@implementation ActionsGroupHeaderRow

- (void)loadContent {
    [super loadContent];

    self.filterLabel = [[NSTextField staticLabelWithString:@"For changes in:" style:self.metrics[@"columnHeaderStyle"]] addedToView:self];

    [self addConstraintsWithVisualFormat:@"|-indentL1-[titleLabel]-(>=columnGapMin)-[filterLabel]" options:NSLayoutFormatAlignAllBaseline];
    [self addFullHeightConstraintsForSubview:self.titleLabel];

    [self alignView:self.titleLabel toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.filterLabel toColumnNamed:@"filter"];
}

@end
