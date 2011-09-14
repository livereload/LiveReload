
#import "StatusItemView.h"
#import "MainWindowController.h"


typedef enum {
    StatusItemStateInactive,
    StatusItemStateActive,
    StatusItemStateRotation1,
    StatusItemStateRotation2,
    StatusItemStateHighlighted,
    StatusItemStateDroppable,
    COUNT_StatusItemState
} StatusItemState;

static NSString *const iconNames[COUNT_StatusItemState] = {
    @"StatusItemInactive",
    @"StatusItemActive",
    @"StatusItemStateRotation1",
    @"StatusItemStateRotation2",
    @"StatusItemHighlighted",
    @"StatusItemDropTarget",
};

enum { kAnimationStepCount = StatusItemStateRotation2 - StatusItemStateActive + 1 };


@implementation StatusItemView

@synthesize selected=_selected;
@synthesize active=_active;
@synthesize droppable=_droppable;
@synthesize delegate=_delegate;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    }
    return self;
}

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
    } else if (_animating) {
        state = StatusItemStateActive + _animationStep;
    } else if (_droppable) {
        state = StatusItemStateDroppable;
    } else if (_active) {
        state = StatusItemStateActive;
    } else {
        state = StatusItemStateInactive;
    }

    NSImage *icon = [self iconForState:state];
    NSSize size = [icon size];
    [icon drawInRect:NSMakeRect(2, 2, size.width, size.height)
            fromRect:NSMakeRect(0, 0, size.width, size.height)
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

- (void)setDroppable:(BOOL)droppable {
    _droppable = droppable;
    [self setNeedsDisplay:YES];
}


#pragma mark - Animation

- (void)_startAnimation {
    _animating = YES;
    _animationStep = 1;
    _continueAnimationRequested = NO;
    _animationTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_animate) userInfo:nil repeats:YES] retain];
    [self display];
}

- (void)_endAnimation {
    [_animationTimer invalidate];
    [_animationTimer release], _animationTimer = nil;
    _animating = NO;
    [self display];
}

- (void)_maybeEndAnimation {
    if (_animationRequests == 0 && !_continueAnimationRequested) {
        [self _endAnimation];
    }
}

- (void)animateOnce {
    if (!_animating) {
        [self _startAnimation];
    } else {
        _continueAnimationRequested = YES;
    }
}

- (void)_animate {
    if (++_animationStep == kAnimationStepCount) {
        _animationStep = 0;
    }
    [self display];
    if (_animationStep == 0) {
        [self _maybeEndAnimation];
        _continueAnimationRequested = NO;
    }
}

- (void)startAnimation {
    ++_animationRequests;
    if (!_animating) {
        [self _startAnimation];
    }
}

- (void)endAnimation {
    --_animationRequests;
    if (_animationStep == 0) {
        // avoid another animation loop if the animation is no longer desired
        [self _maybeEndAnimation];
    } else {
        // NOP; the animation will end when a loop is finished
    }
}


#pragma mark - Dragging

- (NSArray *)sanitizedPathsFrom:(NSPasteboard *)pboard {
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSFileManager *fm = [NSFileManager defaultManager];
        for (NSString *path in files) {
            BOOL dir;
            if (![fm fileExistsAtPath:path isDirectory:&dir]) {
                return nil;
            } else if (!dir) {
                return nil;
            }
        }
        return files;
    }
    return nil;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    BOOL genericSupported = (NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric;
    NSArray *files = [self sanitizedPathsFrom:[sender draggingPasteboard]];
    if (genericSupported && [files count] > 0) {
        self.droppable = YES;
        return NSDragOperationGeneric;
    } else {
        self.droppable = NO;
        return NSDragOperationNone;
    }
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    self.droppable = NO;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    BOOL genericSupported = (NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric;
    NSArray *pathes = [self sanitizedPathsFrom:[sender draggingPasteboard]];

    if (genericSupported && [pathes count] > 0) {
        NSMutableArray * resolvedPaths = [NSMutableArray arrayWithCapacity:[pathes count]];
        for( NSString * str in pathes ) {
            [resolvedPaths addObject:[str stringByResolvingSymlinksInPath]];
        }

        [_delegate statusItemView:self acceptedDroppedDirectories:resolvedPaths];
        return YES;
    } else {
        self.droppable = NO;
        return NO;
    }
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    self.droppable = NO;
}

@end
