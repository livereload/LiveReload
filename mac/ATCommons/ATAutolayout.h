
#import <Foundation/Foundation.h>
#import "ATGlobals.h"


@interface NSView (ATAutolayout)

- (void)replaceSubviewPreservingConstraints:(NSView *)oldView with:(NSView *)newView;

- (void)replaceWithViewPreservingConstraints:(NSView *)newView;

@property(nonatomic, copy) NSDictionary *AT_metrics;

- (NSArray *)constraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts;

- (NSArray *)addConstraintsWithVisualFormat:(NSString *)format;
- (NSArray *)addConstraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts;
- (NSArray *)addConstraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts referencingPropertiesOfObject:(id)owner;

- (NSArray *)addFullHeightConstraintsForSubview:(NSView *)subview;

- (NSLayoutConstraint *)constraintMakingWidthEqualTo:(CGFloat)value;
- (NSLayoutConstraint *)constraintMakingWidthGreaterThanOrEqualTo:(CGFloat)value;
- (NSLayoutConstraint *)constraintMakingWidthLessThanOrEqualTo:(CGFloat)value;

- (NSLayoutConstraint *)constraintMakingHeightEqualTo:(CGFloat)value;
- (NSLayoutConstraint *)constraintMakingHeightGreaterThanOrEqualTo:(CGFloat)value;
- (NSLayoutConstraint *)constraintMakingHeightLessThanOrEqualTo:(CGFloat)value;

- (NSLayoutConstraint *)makeWidthEqualTo:(CGFloat)value;
- (NSLayoutConstraint *)makeWidthGreaterThanOrEqualTo:(CGFloat)value;
- (NSLayoutConstraint *)makeWidthLessThanOrEqualTo:(CGFloat)value;

- (NSLayoutConstraint *)makeHeightEqualTo:(CGFloat)value;
- (NSLayoutConstraint *)makeHeightGreaterThanOrEqualTo:(CGFloat)value;
- (NSLayoutConstraint *)makeHeightLessThanOrEqualTo:(CGFloat)value;

@end


@interface NSLayoutConstraint (ATAutolayout)

- (instancetype)withPriority:(NSLayoutPriority)priority;

@end