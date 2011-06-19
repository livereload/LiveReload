
#import <Cocoa/Cocoa.h>


@class MainWindowController;
@protocol StatusItemViewDelegate;


@interface StatusItemView : NSView {
    __weak id<StatusItemViewDelegate> _delegate;

    NSImage *_icons[4];

    BOOL _selected;
    BOOL _active;
    BOOL _blinking;
}

@property(nonatomic, assign) __weak id<StatusItemViewDelegate> delegate;

@property(nonatomic) BOOL selected;
@property(nonatomic) BOOL active;

- (void)blink;

@end


@protocol StatusItemViewDelegate <NSObject>

- (void)statusItemView:(StatusItemView *)view clickedAtPoint:(NSPoint)pt;

@end