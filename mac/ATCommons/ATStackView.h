
#import <Cocoa/Cocoa.h>


@protocol ATStackViewDelegate;


@interface ATStackView : NSView

@property(nonatomic, weak) IBOutlet id<ATStackViewDelegate> delegate;

@property(nonatomic) CGFloat itemSpacing;

- (void)removeAllItems;
- (void)addItem:(NSView *)itemView;
- (void)insertItem:(NSView *)itemView atIndex:(NSInteger)index;

@end


@interface ATStackViewRow : NSView

- (id)init;

@property(nonatomic, strong) id representedObject;

@end


@protocol ATStackViewDelegate <NSObject>

- (ATStackViewRow *)newRowForItemAtIndex:(NSUInteger)index;

@end
