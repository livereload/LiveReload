
#import "StatusItemView.h"
#import "MainWindowController.h"


@implementation StatusItemView

@synthesize selected=_selected;
@synthesize delegate=_delegate;

- (void)drawRect:(NSRect)rect {
    if (_selected) {
        [[NSColor selectedMenuItemColor] set];
        NSRectFill(rect);
    }

    NSString *text = @"LR";

    NSColor *textColor = [NSColor controlTextColor];
    if (_selected) {
        textColor = [NSColor selectedMenuItemTextColor];
    }

    NSFont *msgFont = [NSFont menuBarFontOfSize:15.0];
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    [paraStyle setAlignment:NSCenterTextAlignment];
    [paraStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    NSMutableDictionary *msgAttrs = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     msgFont, NSFontAttributeName,
                                     textColor, NSForegroundColorAttributeName,
                                     paraStyle, NSParagraphStyleAttributeName,
                                     nil];
    [paraStyle release];

    NSSize msgSize = [text sizeWithAttributes:msgAttrs];
    NSRect msgRect = NSMakeRect(0, 0, msgSize.width, msgSize.height);
    msgRect.origin.x = ([self frame].size.width - msgSize.width) / 2.0;
    msgRect.origin.y = ([self frame].size.height - msgSize.height) / 2.0;

    [text drawInRect:msgRect withAttributes:msgAttrs];
}

- (void)mouseDown:(NSEvent *)event {
    NSRect frame = [[self window] frame];
    NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
    [_delegate statusItemView:self clickedAtPoint:pt];
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    [self setNeedsDisplay:YES];
}

@end
