@import LRCommons;

#import "GroupHeaderRow.h"


@implementation GroupHeaderRow

- (NSDictionary *)metaInfo {
    return self.representedObject;
}

- (void)loadContent {
    [super loadContent];
    
    _titleLabel = [[NSTextField staticLabelWithString:self.metaInfo[@"title"]] addedToView:self];
    _titleLabel.font = [NSFont boldSystemFontOfSize:13.0];

    self.topMargin = 30.0;
    self.bottomMargin = 8.0;
}

@end


@implementation CompilersCategoryRow : GroupHeaderRow
@end


@implementation FiltersCategoryRow : GroupHeaderRow
@end
