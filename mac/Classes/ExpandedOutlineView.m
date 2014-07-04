
#import "ExpandedOutlineView.h"

@implementation ExpandedOutlineView

#define kOutlineCellWidth 11
#define kOutlineMinLeftMargin 6

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row {
    NSRect superFrame = [super frameOfCellAtColumn:column row:row];
    if (column == 0) {
        // expand by kOutlineCellWidth to the left to cancel the indent
        CGFloat adjustment = kOutlineCellWidth;

        // ...but be extra defensive because we have no fucking idea what is going on here
        if (superFrame.origin.x - adjustment < kOutlineMinLeftMargin) {
            NSLog(@"%@ adjustment amount is incorrect: adjustment = %f, superFrame = %@, kOutlineMinLeftMargin = %f", NSStringFromClass([self class]), (float)adjustment, NSStringFromRect(superFrame), (float)kOutlineMinLeftMargin);
            adjustment = MAX(0, superFrame.origin.x - kOutlineMinLeftMargin);
        }

        return NSMakeRect(superFrame.origin.x - adjustment, superFrame.origin.y, superFrame.size.width + adjustment, superFrame.size.height);
    }
    return superFrame;
}

@end
