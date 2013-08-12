
#import <Cocoa/Cocoa.h>


@protocol ATStackViewDelegate;


typedef enum {
    ATStackViewColumnAlignmentLeading,
    ATStackViewColumnAlignmentTrailing,
    ATStackViewColumnAlignmentBothSides,
} ATStackViewColumnAlignment;


@interface ATStackView : NSView

@property(nonatomic, weak) IBOutlet id<ATStackViewDelegate> delegate;

- (void)removeAllItems;
- (void)addItem:(NSView *)itemView;
- (void)insertItem:(NSView *)itemView atIndex:(NSInteger)index;

@end


@interface ATStackViewRow : NSView

+ (id)rowWithRepresentedObject:(id)representedObject metrics:(NSDictionary*)metrics delegate:(id)delegate;

- (id)init;
- (id)initWithRepresentedObject:(id)representedObject metrics:(NSDictionary*)metrics delegate:(id)delegate;

@property(nonatomic, strong) id representedObject;
@property(nonatomic, copy) NSDictionary *metrics;
@property(nonatomic, weak) id delegate;

// interrow gap (will use a maximum for the adjacent rows; top gap ignored for the first row, bottom gap ignored for the last one)
@property(nonatomic) CGFloat topMargin;
@property(nonatomic) CGFloat bottomMargin;

- (void)loadContentIfNeeded;

- (void)loadContent;  // override point; do not invoke directly

- (void)alignView:(NSView *)view toColumnNamed:(NSString *)columnName;
- (void)alignView:(NSView *)view toColumnNamed:(NSString *)columnName alignment:(ATStackViewColumnAlignment)alignment;

@property(nonatomic, strong) NSArray *childRows;

@property(nonatomic, assign) BOOL collapsed;
- (void)setCollapsed:(BOOL)collapsed animated:(BOOL)animated;

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
