
#import "PassThruView.h"

@implementation PassThruView

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
