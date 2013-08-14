
#import "ActionsGroupHeaderRow.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"

@implementation ActionsGroupHeaderRow

- (void)loadContent {
    [super loadContent];

    self.filterLabel = [[NSTextField staticLabelWithString:@"When" style:self.metrics[@"columnHeaderStyle"]] addedToView:self];

    [self addConstraintsWithVisualFormat:@"|[titleLabel]-(>=columnGapMin)-[filterLabel]" options:NSLayoutFormatAlignAllBaseline];
    [self addFullHeightConstraintsForSubview:self.titleLabel];

    [self alignView:self.titleLabel toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.filterLabel toColumnNamed:@"filter"];
}

@end
