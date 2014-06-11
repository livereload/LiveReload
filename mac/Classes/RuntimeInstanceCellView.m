
#import "RuntimeInstanceCellView.h"

@implementation RuntimeInstanceCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    [super setBackgroundStyle:backgroundStyle];
    self.detailTextField.textColor = (backgroundStyle == NSBackgroundStyleLight ? [NSColor darkGrayColor] : [NSColor colorWithCalibratedWhite:0.85 alpha:1.0]);
}

@end
