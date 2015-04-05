
#import "ShadowBoxView.h"
@import LRCommons;


@implementation ShadowBoxView

- (void)drawRect:(NSRect)dirtyRect {
    NSColor *backgroundColor = [NSColor colorWithHexValue:0xb3b8bf alpha:1.0];
    NSColor *shadowColor = [NSColor colorWithHexValue:0x000000 alpha:0.5];
    NSColor *borderColor = [NSColor colorWithHexValue:0x7d8087 alpha:1.0];
    CGFloat shadowSize = 1.0; /* plus 1px border */

    CGContextRef ctx = NSGraphicsGetCurrentContext();

    const CGFloat overhang = 5.0;

    CGRect bounds = self.bounds;
    CGRect leftShadow = CGRectMake(bounds.origin.x - overhang + 1, bounds.origin.y - overhang, overhang, bounds.size.height + 2 * overhang);

    CGContextSetFillColorWithColor(ctx, backgroundColor.CGColor);
    CGContextFillRect(ctx, bounds);

    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeZero, shadowSize, shadowColor.CGColor);
    CGContextSetFillColorWithColor(ctx, borderColor.CGColor);
    CGContextAddRect(ctx, leftShadow);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
}

@end
