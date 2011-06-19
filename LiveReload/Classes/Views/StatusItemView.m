
#import "StatusItemView.h"
#import "MainWindowController.h"


typedef enum {
    StatusItemStateInactive,
    StatusItemStateActive,
    StatusItemStateHighlighted,
    StatusItemStateBlinking,
    COUNT_StatusItemState
} StatusItemState;

static NSString *const iconNames[COUNT_StatusItemState] = {
    @"StatusItemInactive",
    @"StatusItemActive",
    @"StatusItemHighlighted",
    @"StatusItemBlinking",
};


@implementation StatusItemView

@synthesize selected=_selected;
@synthesize active=_active;
@synthesize delegate=_delegate;

- (NSImage *)iconForState:(StatusItemState)state {
    NSImage *result = _icons[state];
    if (result == nil) {
        result = _icons[state] = [NSImage imageNamed:iconNames[state]];
    }
    return result;
}

- (void)drawRect:(NSRect)rect {
    if (_selected) {
        [[NSColor selectedMenuItemColor] set];
        NSRectFill(rect);
    }

    StatusItemState state;
    if (_selected) {
        state = StatusItemStateHighlighted;
    } else if (_blinking) {
        state = StatusItemStateBlinking;
    } else if (_active) {
        state = StatusItemStateActive;
    } else {
        state = StatusItemStateInactive;
    }

    NSImage *icon = [self iconForState:state];
    NSSize size = [icon size];
    [icon drawInRect:CGRectMake(0, 1, size.width, size.height)
            fromRect:CGRectMake(0, 0, size.width, size.height)
           operation:NSCompositeSourceOver
            fraction:1.0];
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

- (void)setActive:(BOOL)active {
    _active = active;
    [self setNeedsDisplay:YES];
}

- (void)blink {
    if (!_blinking) {
        _blinking = YES;
        [self display];
        [self performSelector:@selector(_stopBlinking) withObject:nil afterDelay:0.1];
    }
}

- (void)_stopBlinking {
    _blinking = NO;
    [self display];
}

@end
