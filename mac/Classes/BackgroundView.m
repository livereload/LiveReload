
#import "BackgroundView.h"
@import LRCommons;


@implementation BackgroundView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (BOOL)isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    CGRect bounds = self.bounds;
    CGRect box = CGRectInset(bounds, 1, 1);

    CGRect header = box;
    header.origin.y += 1 /* top border */;
    header.size.height = 86; // not including the mid border

    CGRect main = box;
    main.origin.y += 1 /* top border */ + header.size.height + 1 /* mid border */;
    main.size.height = box.size.height - (main.origin.y - box.origin.y);

    NSBezierPath *boxBorder = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(box, 0.5, 0.5) xRadius:4 yRadius:4];

//    NSColor *backgroundColor = [NSColor colorWithHexValue:0xb3b8bf alpha:1.0];
    NSColor *whiteColor = [NSColor colorWithHexValue:0xffffff alpha:1.0];
//    NSColor *headerColor = [NSColor colorWithHexValue:0xe2e4e5 alpha:1.0];
    NSColor *headerGradientStartColor = [NSColor colorWithHexValue:0xebeced alpha:1.0];
    NSColor *headerGradientEndColor = [NSColor colorWithHexValue:0xd4d5d6 alpha:1.0];
    NSColor *borderColor = [NSColor colorWithHexValue:0x7d8087 alpha:1.0];
    NSColor *headerBorderColor = [NSColor colorWithHexValue:0x9f9f9f alpha:1.0];
    NSColor *shadowColor = [NSColor colorWithHexValue:0x000000 alpha:0.5];

//    CGContextRef c = (CGContextRef)[NSGraphicsContext currentContext].graphicsPort;
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];

//    [backgroundColor setFill];
//    NSRectFill(bounds);

    NSShadow* theShadow = [[NSShadow alloc] init];
    [theShadow setShadowOffset:NSMakeSize(0, 0)];
    [theShadow setShadowBlurRadius:1.0];
    [theShadow setShadowColor:shadowColor];

    [ctx saveGraphicsState];
    [theShadow set];
    [borderColor set];
    [boxBorder stroke];
    [ctx restoreGraphicsState];

    [ctx saveGraphicsState];
    [boxBorder addClip];

    [whiteColor setFill];
    NSRectFill(main);

    NSGradient *headerGradient = [[NSGradient alloc] initWithStartingColor:headerGradientStartColor endingColor:headerGradientEndColor];
    [headerGradient drawInRect:header angle:90];

    [headerBorderColor setFill];
    NSRectFill(CGRectMake(header.origin.x, CGRectGetMaxY(header), header.size.width, 1));

    [ctx restoreGraphicsState];

    [borderColor setStroke];
    [boxBorder stroke];
}

@end
