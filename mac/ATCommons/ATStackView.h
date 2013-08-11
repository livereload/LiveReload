
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
@property(nonatomic, copy) NSDictionary *metrics;

@end


@interface ATStackViewGroup : NSObject

- (id)init;

@property(nonatomic, strong) NSArray *representedObjects;
@property(nonatomic, strong, readonly) NSArray *children;

@end


@interface ATStackViewMappedGroup : ATStackViewGroup

- (id)init;

@property(nonatomic, strong, readonly) NSArray *items;

- (ATStackViewRow *)newRowForItem:(id)item;

@end


@protocol ATStackViewDelegate <NSObject>

- (ATStackViewRow *)newRowForItemAtIndex:(NSUInteger)index;

- (NSArray *)childrenOfRow:(ATStackViewRow *)row;

@end
