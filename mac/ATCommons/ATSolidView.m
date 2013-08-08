
#import "ATSolidView.h"

@implementation ATSolidView

- (void)drawRect:(NSRect)dirtyRect {
    NSColor *backgroundColor = _backgroundColor ?: [NSColor redColor];
    [backgroundColor setFill];
    NSRectFill(self.bounds);
}

@end
