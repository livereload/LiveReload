
#import "RubyInstance.h"


@class HomebrewContainer;


@interface HomebrewRubyInstance : RubyInstance

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name container:(HomebrewContainer *)container;

@end
