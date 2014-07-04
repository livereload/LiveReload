
#import "RubyInstance.h"


@class RvmContainer;


@interface RvmRubyInstance : RubyInstance

- (id)initWithIdentifier:(NSString *)identifier name:(NSString *)name container:(RvmContainer *)container;

@end
