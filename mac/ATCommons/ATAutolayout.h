
#import <Foundation/Foundation.h>
#import "ATGlobals.h"

@interface NSView (ATAutolayout)

- (void)replaceSubviewPreservingConstraints:(NSView *)oldView with:(NSView *)newView;

- (void)replaceWithViewPreservingConstraints:(NSView *)newView;

@property(nonatomic, copy) NSDictionary *AT_metrics;

- (NSArray *)constraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts;
- (NSArray *)addConstraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts;
- (NSArray *)addConstraintsWithVisualFormat:(NSString *)format;

- (NSArray *)addFullHeightConstraintsForSubview:(NSView *)subview;

@end
