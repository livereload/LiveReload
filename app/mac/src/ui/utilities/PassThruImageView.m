
#import "PassThruImageView.h"

@implementation PassThruImageView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self unregisterDraggedTypes];
    }
    return self;
}

- (NSView *)hitTest:(NSPoint)aPoint {
    return nil;
}

- (BOOL)mouse:(NSPoint)aPoint inRect:(NSRect)aRect {
    return NO;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return NO;
}

@end
