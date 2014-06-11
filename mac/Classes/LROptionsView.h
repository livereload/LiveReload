
#import <Cocoa/Cocoa.h>


enum {
    LROptionsViewRightEdgeExpansionPriority = 100,
    LROptionsViewContentHuggingExpandToRightEdge = LROptionsViewRightEdgeExpansionPriority - 10,
};

typedef enum {
    LROptionsViewFlagsLabelAlignmentBaseline = 0,
    LROptionsViewFlagsLabelAlignmentCenter = 1,
    LROptionsViewFlagsLabelAlignmentTop = 2,

    LROptionsViewFlagsLabelAlignmentMask = 0x7,
} LROptionsViewFlags;


@class LROption;


@interface LROptionsView : NSView

+ (LROptionsView *)optionsView;

- (void)addOption:(LROption *)option;
- (void)addOptionView:(NSView *)optionView withLabel:(NSString *)label flags:(LROptionsViewFlags)flags;
- (void)addOptionView:(NSView *)optionView withLabel:(NSString *)label alignedToView:(NSView *)labelAlignmentView flags:(LROptionsViewFlags)flags;

@end
