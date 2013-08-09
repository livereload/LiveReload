
#import <Cocoa/Cocoa.h>

@interface ATStackView : NSView

@property(nonatomic) CGFloat itemSpacing;

- (void)removeAllItems;
- (void)addItem:(NSView *)itemView;
- (void)insertItem:(NSView *)itemView atIndex:(NSInteger)index;

@end
