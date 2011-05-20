
#import <Cocoa/Cocoa.h>


@class MainWindowController;
@protocol StatusItemViewDelegate;


@interface StatusItemView : NSView {
    BOOL _selected;
    __weak id<StatusItemViewDelegate> _delegate;
}

@property(nonatomic) BOOL selected;
@property(nonatomic, assign) __weak id<StatusItemViewDelegate> delegate;

@end


@protocol StatusItemViewDelegate <NSObject>

- (void)statusItemView:(StatusItemView *)view clickedAtPoint:(NSPoint)pt;

@end