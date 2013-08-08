
#import <Foundation/Foundation.h>
#import "ATGlobals.h"

@interface NSView (ATAutolayout)

- (void)replaceSubviewPreservingConstraints:(NSView *)oldView with:(NSView *)newView;

- (void)replaceWithViewPreservingConstraints:(NSView *)newView;

@end
