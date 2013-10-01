
#import "FiltersGroupHeaderRow.h"
#import "ATMacViewCreation.h"
#import "ATAutolayout.h"


@implementation FiltersGroupHeaderRow

- (void)loadContent {
    [super loadContent];

    self.fromLabel = [[NSTextField staticLabelWithString:@"Source" style:self.metrics[@"columnHeaderStyle"]] addedToView:self];
    self.toLabel = [[NSTextField staticLabelWithString:@"Output" style:self.metrics[@"columnHeaderStyle"]] addedToView:self];

    [self addConstraintsWithVisualFormat:@"|[titleLabel]-(>=columnGapMin)-[fromLabel]-columnGapMin-[toLabel]" options:NSLayoutFormatAlignAllBaseline];
    [self addFullHeightConstraintsForSubview:self.titleLabel];

    [self alignView:self.titleLabel toColumnNamed:@"actionRightEdge" alignment:ATStackViewColumnAlignmentTrailing];
    [self alignView:self.fromLabel toColumnNamed:@"from"];
    [self alignView:self.toLabel toColumnNamed:@"to"];
}

@end
