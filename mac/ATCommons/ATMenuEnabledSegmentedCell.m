
#import "ATMenuEnabledSegmentedCell.h"

static NSRect ATCenterSizeInRect(NSSize size, NSRect outer) {
    return NSMakeRect(outer.origin.x + (outer.size.width - size.width) / 2,
                      outer.origin.y + (outer.size.height - size.height) / 2,
                      size.width, size.height);
}


@implementation ATMenuEnabledSegmentedCell {
    NSButtonCell *_fakeButtonCell;
}

// see: http://stackoverflow.com/questions/1203698/show-nssegmentedcontrol-menu-when-segment-clicked-despite-having-set-action

- (SEL)action {
    if ([self menuForSegment:self.selectedSegment])
        return nil;
    else
        return [super action];
}

- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView {
    NSImage *image = [self imageForSegment:segment];
    NSString *label = [self labelForSegment:segment];
    if (!label || image) {
        [super drawSegment:segment inFrame:frame withView:controlView];
    } else {
        // use a button look instead of a segmented control look
#if 0
        // option A: custom drawing (works, but I ultimately picked option B)
        NSDictionary *attributes = @{NSFontAttributeName: self.font};
        NSRect boundingRect = [label boundingRectWithSize:frame.size options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
        NSRect rect = ATCenterSizeInRect(boundingRect.size, frame);
        rect = [controlView backingAlignedRect:rect options:NSAlignMinXOutward|NSAlignMinYOutward|NSAlignWidthOutward|NSAlignMaxYOutward];
        [label drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes];
#else
        // option B: delegate to NSButtonCell (I feel this is a safer approach, so went with it)
        if (!_fakeButtonCell)
            _fakeButtonCell = [NSButtonCell new];
        [_fakeButtonCell setFont:self.font];
        [_fakeButtonCell setBordered:NO];
        [_fakeButtonCell setButtonType:NSMomentaryChangeButton]; // gets rid of the white background in pressed state
        [_fakeButtonCell setBackgroundStyle:self.backgroundStyle];
        [_fakeButtonCell setTitle:label];
        [_fakeButtonCell setHighlighted:(self.selectedSegment == segment)];
        [_fakeButtonCell setEnabled:[self isEnabled]];
        [_fakeButtonCell setLineBreakMode:self.lineBreakMode];

        // these two don't seem to do anything, but reset them for 'extra safety'
        [_fakeButtonCell setGradientType:NSGradientNone];
        [_fakeButtonCell setBezelStyle:NSRegularSquareBezelStyle];

        [_fakeButtonCell setControlView:controlView];
        [_fakeButtonCell drawWithFrame:frame inView:controlView];
#endif
    }
}

@end
