
#import "RubyInstance.h"


@class RbenvContainer;


@interface RbenvRubyInstance : RubyInstance

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name container:(RbenvContainer *)container;

@end
