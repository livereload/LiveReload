
#import <Cocoa/Cocoa.h>


@class MainWindowController;
@protocol StatusItemViewDelegate;


@interface StatusItemView : NSView {
    __weak id<StatusItemViewDelegate> _delegate;

    NSImage *_icons[7];

    BOOL _selected;
    BOOL _active;
    BOOL _animating;
    BOOL _continueAnimationRequested;
    BOOL _droppable;

    NSInteger              _animationRequests;
    NSInteger              _animationStep;
    NSTimer               *_animationTimer;
}

@property(nonatomic, assign) __weak id<StatusItemViewDelegate> delegate;

@property(nonatomic) BOOL selected;
@property(nonatomic) BOOL active;
@property(nonatomic) BOOL droppable;

- (void)animateOnce;
- (void)startAnimation;
- (void)endAnimation;

@end


@protocol StatusItemViewDelegate <NSObject>

- (void)statusItemView:(StatusItemView *)view clickedAtPoint:(NSPoint)pt;
- (void)statusItemView:(StatusItemView *)view acceptedDroppedDirectories:(NSArray *)pathes;

@end