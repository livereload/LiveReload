
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


@interface LROptionsView : NSView

+ (LROptionsView *)optionsView;

- (void)addOptionView:(NSView *)optionView label:(NSString *)label flags:(LROptionsViewFlags)flags;

@end
