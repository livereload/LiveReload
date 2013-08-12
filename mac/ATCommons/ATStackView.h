
#import <Cocoa/Cocoa.h>


@protocol ATStackViewDelegate;


@interface ATStackView : NSView

@property(nonatomic, weak) IBOutlet id<ATStackViewDelegate> delegate;

- (void)removeAllItems;
- (void)addItem:(NSView *)itemView;
- (void)insertItem:(NSView *)itemView atIndex:(NSInteger)index;

@end


@interface ATStackViewRow : NSView

- (id)init;

@property(nonatomic, strong) id representedObject;
@property(nonatomic, copy) NSDictionary *metrics;

// interrow gap (will use a maximum for the adjacent rows; top gap ignored for the first row, bottom gap ignored for the last one)
@property(nonatomic) CGFloat topMargin;
@property(nonatomic) CGFloat bottomMargin;

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
